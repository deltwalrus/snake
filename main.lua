import "CoreLibs/graphics"
import "CoreLibs/object"
import "CoreLibs/sprites"
import "CoreLibs/timer"

local gfx = playdate.graphics
local snd = playdate.sound

-- Screen dimensions
local SCREEN_WIDTH = 400
local SCREEN_HEIGHT = 240
local TILE_SIZE = 10

-- Score box dimensions
local SCORE_BOX_WIDTH = 100
local SCORE_BOX_HEIGHT = 20

-- Snake properties
local snake = {
    body = {{x = 20, y = 12}}, -- Initial position
    direction = "right", -- Start direction
    grow = false
}

-- Initialize food position randomly, ensuring it doesn't overlap the score box
local food = {
    x = math.random(0, (SCREEN_WIDTH / TILE_SIZE) - 1),
    y = math.random(0, (SCREEN_HEIGHT / TILE_SIZE) - 1)
}

-- Ensure the food does not appear behind the score box
while food.x * TILE_SIZE < SCORE_BOX_WIDTH and food.y * TILE_SIZE < SCORE_BOX_HEIGHT do
    food.x = math.random(0, (SCREEN_WIDTH / TILE_SIZE) - 1)
    food.y = math.random(0, (SCREEN_HEIGHT / TILE_SIZE) - 1)
end

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

-- Background
local function drawBackground()
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

    gfx.setPattern({
        0x11, 0x22, 0x44, 0x88,
        0x11, 0x22, 0x44, 0x88
    }) -- Light dotted pattern
    gfx.fillRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
end

-- Move the snake
local function moveSnake()
    local head = snake.body[1]
    local newHead = {x = head.x, y = head.y}

    if snake.direction == "up" then
        newHead.y -= 1
    elseif snake.direction == "down" then
        newHead.y += 1
    elseif snake.direction == "left" then
        newHead.x -= 1
    elseif snake.direction == "right" then
        newHead.x += 1
    end

    table.insert(snake.body, 1, newHead)

    if snake.grow then
        snake.grow = false
    else
        table.remove(snake.body) -- Remove the tail
    end
end

-- Check collisions
local function checkCollisions()
    local head = snake.body[1]

    -- Check wall collisions
    if head.x < 0 or head.x >= SCREEN_WIDTH / TILE_SIZE or
       head.y < 0 or head.y >= SCREEN_HEIGHT / TILE_SIZE then
        gameOver = true
        gameOverSound:play()
    end

    -- Check self collisions
    for i = 2, #snake.body do
        if snake.body[i].x == head.x and snake.body[i].y == head.y then
            gameOver = true
            gameOverSound:play()
        end
    end

    -- Check food collision
    if head.x == food.x and head.y == food.y then
        score += 1
        snake.grow = true
        eatSound:play()

        -- Generate new food
        repeat
            food.x = math.random(0, (SCREEN_WIDTH / TILE_SIZE) - 1)
            food.y = math.random(0, (SCREEN_HEIGHT / TILE_SIZE) - 1)
        until not (food.x * TILE_SIZE < SCORE_BOX_WIDTH and food.y * TILE_SIZE < SCORE_BOX_HEIGHT)
    end
end

-- Draw the snake
local function drawSnake()
    for i, segment in ipairs(snake.body) do
        if i == 1 then
            -- Draw the animated snake head
            snakeHeadFrames[currentHeadFrame]:draw(segment.x * TILE_SIZE, segment.y * TILE_SIZE)
        else
            snakeBodyImage:draw(segment.x * TILE_SIZE, segment.y * TILE_SIZE)
        end
    end
end

-- Draw the food
local function drawFood()
    foodImage:draw(food.x * TILE_SIZE, food.y * TILE_SIZE)
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
    until not (food.x * TILE_SIZE < SCORE_BOX_WIDTH and food.y * TILE_SIZE < SCORE_BOX_HEIGHT)
end

-- Input handler
function playdate.upButtonDown()
    if not gameOver and snake.direction ~= "down" then
        snake.direction = "up"
    end
end

function playdate.downButtonDown()
    if not gameOver and snake.direction ~= "up" then
        snake.direction = "down"
    end
end

function playdate.leftButtonDown()
    if not gameOver and snake.direction ~= "right" then
        snake.direction = "left"
    end
end

function playdate.rightButtonDown()
    if not gameOver and snake.direction ~= "left" then
        snake.direction = "right"
    end
end

function playdate.AButtonDown()
    if gameOver then
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

-- Game update loop
function playdate.update()
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
    drawTextWithBackground("Score: " .. score, 0, 0, SCORE_BOX_WIDTH, SCORE_BOX_HEIGHT)
end