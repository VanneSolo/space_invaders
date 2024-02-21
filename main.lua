if arg[arg] == "-debug" then require("mobdebug").start() end
io.stdout:setvbuf('no')

-- 5 lignes, 11 colonnes.
-- En largeur: ecran de 250, 11 sprites de 11 pixels (121) et 5 pixels d'ecartement.
-- (11*11)+(11*5) = 121 + 55 = 176 //// 250-176 = 74 //// 74/2 = 37
-- En hauteur, les sprites des aliens font 8 pixels.

function CheckCollision(x1,y1,w1,h1, x2,y2,w2,h2)
  return x1 < x2+w2 and
         x2 < x1+w1 and
         y1 < y2+h2 and
         y2 < y1+h1
end

function love.load()
  love.window.setMode(250*2, 250*2)
  
  largeur = love.graphics.getWidth()
  hauteur = love.graphics.getHeight()
  
  lignes = 5
  colonnes = 11
  
  liste_aliens = {}
  liste_aliens_bullets = {}
  
  Init_Game()
end

function love.update(dt)
  nb_aliens = 0
  for l=1,lignes do
    for c=1,colonnes do
      local a = liste_aliens[l][c]
      if a.situation == "ALIVE" then
        nb_aliens = nb_aliens + 1
        if love.math.random(1, 10000) <= 4 then
          Cree_Alien_Bullet(a)
        end
      end
      if a.situation == "DEAD" then
        a.chrono_boum = a.chrono_boum - dt
        if a.chrono_boum <= 0 then
          a.situation = "OFF"
        end
      end
    end
  end
  
  if mode == "WIN" then
    return
  end
  
  timer_line_move = timer_line_move + dt
  local b_inv = false
  if timer_line_move > speed_game then
    local a
    for c=1,colonnes do
      a = liste_aliens[last_line][c]
      a.x = a.x + speed
    end
    local first = liste_aliens[1][1]
    local last = liste_aliens[1][colonnes]
    if speed > 0 and last.x > 219 then
      speed = -speed
      b_inv = true
    elseif speed < 0 and first.x < 20 then
      speed = -speed
      b_inv = true
    end
    last_line = last_line - 1
    if last_line < 1 then
      last_line = 5
      if b_inv == true then
        for l=1,lignes do
          for c=1,colonnes do
            local a = liste_aliens[l][c]
            a.y = a.y + 8
          end
        end
      end
    end
    timer_line_move = 0
  end
  
  if love.keyboard.isDown("right") and heros.x < largeur/2-heros.w then
    heros.x = heros.x + 2
  end
  if love.keyboard.isDown("left") and heros.x > 0 then
    heros.x = heros.x - 2
  end
  
  if nb_aliens == 0 then
    mode = "WIN"
  end
    
  if laser ~= nil then
    laser.y = laser.y - 4
    b_stop = false
    for l=1,lignes do
      for c=1,colonnes do
        local a = liste_aliens[l][c]
        if a.situation == "ALIVE" then
          if CheckCollision(laser.x, laser.y, laser.w, laser.h, a.x, a.y, 11, 8) then
            a.situation = "DEAD"
            speed_game = speed_game - 0.001
            b_stop = true
            break
          end
        end
      end
      if b_stop == true then
        break
      end
    end
    if laser.y < 0 then
      laser = nil
    elseif b_stop == true then
      laser = nil
    end
  end
  
  for b=#liste_aliens_bullets,1,-1 do
    local bullet = liste_aliens_bullets[b]
    bullet.y = bullet.y + 2
    if CheckCollision(heros.x, heros.y, heros.w, heros.h, bullet.x, bullet.y, bullet.w, bullet.h) then
      mode = "GAME OVER"
    end
    if bullet.y > hauteur/2 then
      table.remove(liste_aliens_bullets, b)
    end
  end
end

function love.draw()
  love.graphics.scale(2, 2)
  
  if mode == "WIN" then
    love.graphics.print("VICTOIRE", largeur/4, hauteur/4)
  elseif mode == "GAME OVER" then
    love.graphics.print("DEFAITE", largeur/4, hauteur/4)
  else
    for l=1,lignes do
      for c=1,colonnes do
        local a = liste_aliens[l][c]
        if a.situation == "ALIVE" then
          love.graphics.rectangle("line", a.x, a.y, a.w, a.h)
        elseif a.situation == "DEAD" then
          love.graphics.print("M", a.x, a.y)
        end
      end
    end
    love.graphics.rectangle("line", heros.x, heros.y, heros.w, heros.h)
    if laser ~= nil then
      love.graphics.rectangle("line", laser.x, laser.y, 2, 10)
    end
    for b=1,#liste_aliens_bullets do
      local bullet = liste_aliens_bullets[b]
      love.graphics.rectangle("line", bullet.x, bullet.y, bullet.w, bullet.h)
    end
  end
  love.graphics.print(tostring(nb_aliens))
end

function love.keypressed(key)
  if key == "space" and laser == nil and mode == "PLAY" then
    Cree_Tir()
  elseif key == "space" and mode == "GAME OVER" then
    Init_Game()
  end
end

function Cree_Aliens(pX, pY, pW, pH)
  local alien = {}
  alien.w = pW
  alien.h = pH
  alien.x = pX
  alien.y = pY
  alien.situation = "ALIVE"
  alien.chrono_boum = 1
  return alien
end

function Init_Alien()
  local xx, yy = 0, 0
  xx = 37
  yy = 30
  liste_aliens = {}
  for l=1,lignes do
    xx = 37
    liste_aliens[l] = {}
    for c=1,colonnes do
      local a = Cree_Aliens(xx, yy, 11, 8)
      liste_aliens[l][c] = a
      xx = xx + 11 + 5
    end
    yy = yy + 11
  end
end

function Cree_Heros()
  heros = {}
  heros.w = 14
  heros.h = 10
  heros.x = largeur/4 - heros.w/2
  heros.y = hauteur/2 - 30
end

function Cree_Tir()
  laser = {}
  laser.w = 1
  laser.h = 4
  laser.x = heros.x + (heros.w/2)
  laser.y = heros.y
end

function Cree_Alien_Bullet(pAlien)
  local bullet = {}
  bullet.w = 1
  bullet.h = 4
  bullet.x = pAlien.x + (pAlien.w/2)
  bullet.y = pAlien.y + 8
  table.insert(liste_aliens_bullets, bullet)
end

function Init_Game()
  Init_Alien()
  Cree_Heros()
  mode = "PLAY"
  timer_line_move = 0
  last_line = 5
  speed_game = 0.1
  speed = 2
end