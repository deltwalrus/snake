import "CoreLibs/graphics"
import "CoreLibs/object"
import "CoreLibs/sprites"
import "CoreLibs/timer"

local gfx = playdate.graphics
local snd = playdate.sound

-- Screen dimensions
local SCREEN_WIDTH = 400
local SCREEN_HEIGHT = 240

-- Game states
local state = "title" -- "title" or "playing"

-- Snake properties
local TILE_SIZE = 10
local snake = {
    body = {{x = 20, y = 12}}, -- Initial position
    direction = "right", -- Start direction
    grow = false
}

-- Food position
local food = {x = 10, y = 10}

-- Game state
local score = 0
local gameOver = false

-- Animation state
local snakeHeadFrames = {
    gfx.image.new("images/snake-head-frame1.png"),
    gfx.image.new("images/snake-head-frame2.png")
}
local currentHeadFrame = 1
local animationTimer = nil

-- Load other images
local snakeBodyImage = gfx.image.new("images/snake-body.png")
local foodImage = gfx.image.new("images/food.png")

-- Sounds
local eatSound = snd.sampleplayer.new("sounds/eat.wav")
local gameOverSound = snd.sampleplayer.new("sounds/game-over.wav")

-- Draw the title screen
local function drawTitleScreen()
    gfx.clear()
    
    -- Background
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
    
    gfx.setPattern({
        0x11, 0x22, 0x44, 0x88,
        0x11, 0x22, 0x44, 0x88
    }) -- Dotted pattern
    gfx.fillRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

    -- Title Text
    gfx.setFont(gfx.kFontLarge)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawText("NEK", 150, 100) -- Draw "NEK" part of "SNEK"
    
    -- Snake "S"
    local x, y = 120, 100
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(x, y, 8) -- Snake head
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(x - 2, y - 2, 3) -- Snake eye

    -- Snake body forming "S"
    gfx.setColor(gfx.kColorBlack)
    gfx.drawLine(x - 8, y + 5, x - 16, y + 10) -- Snake curve 1
    gfx.drawLine(x - 16, y + 10, x - 8, y + 20) -- Snake curve 2
    gfx.drawLine(x - 8, y + 20, x, y + 25)      -- Snake curve 3
    gfx.drawLine(x, y + 25, x - 8, y + 35)      -- Snake tail

    -- Start prompt
    gfx.setFont(gfx.kFontSmall)
    gfx.drawTextAligned("Press A to Start", SCREEN_WIDTH / 2, 200, kTextAlignment.center)
end

-- Restart game logic
local function restartGame()
    snake.body = {{x = 20, y = 12}}
    snake.direction = "right"
    snake.grow = false
    score = 0
    gameOver = false

    -- Randomize initial food position
    repeat
        food.x = math.random(0, (SCREEN_WIDTH / TILE_SIZE) - 1)
        food.y = math.random(0, (SCREEN_HEIGHT / TILE_SIZE) - 1)
    until not (food.x * TILE_SIZE < 100 and food.y * TILE_SIZE < 20)
end

-- Input handler
function playdate.AButtonDown()
    if state == "title" then
        state = "playing"
        restartGame()
    elseif gameOver then
        restartGame()
    end
end

-- Timer for animation
local function toggleAnimationFrame()
    currentHeadFrame = 3 - currentHeadFrame -- Toggle between 1 and 2
end

-- Initialize animation timer
animationTimer = playdate.timer.keyRepeatTimerWithDelay(500, 200, toggleAnimationFrame)

-- Draw text with very light background
local function drawTextWithBackground(text, x, y, width, height)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(x, y, width, height) -- Solid white background
    gfx.setColor(gfx.kColorBlack)
    gfx.drawTextAligned(text, x + width / 2, y + (height / 2) - 8, kTextAlignment.center)
end

-- Main game update loop
function playdate.update()
    if state == "title" then
        drawTitleScreen()
        return
    end

    if gameOver then
        -- Draw "Game Over" screen
        drawTextWithBackground("Game Over!", 50, 80, 300, 40)
        drawTextWithBackground("Press A to Restart", 50, 130, 300, 40)
        return
    end

    -- Clear the screen and draw
    gfx.clear()
    drawBackground()
    moveSnake()
    checkCollisions()
    drawSnake()
    drawFood()

    -- Draw score
    drawTextWithBackground("Score: " .. score, 0, 0, 100, 20)
end