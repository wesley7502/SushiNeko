//
//  GameScene.swift
//  SushiNeko
//
//  Created by Tsai Family on 6/27/16.
//  Copyright (c) 2016 MakeSchool. All rights reserved.
//

import SpriteKit

/* Tracking enum for use with character and sushi side */
enum Side {
    case Left, Right, None
}

/* Tracking enum for game state */
enum GameState {
    case Title, Ready, Playing, GameOver
}


class GameScene: SKScene {
    
    /* Game objects */
    var sushiBasePiece: SushiPiece!
    var character: Character!
    var healthBar: SKSpriteNode!
    
    var scoreLabel: SKLabelNode!
    
    /* Sushi tower array */
    var sushiTower: [SushiPiece] = []
    
    /* Game management */
    var state: GameState = .Title
    
    var playButton: MSButtonNode!
    
    var health: CGFloat = 1.0 {
        didSet {
            /* Cap Health */
            if health > 1.0 { health = 1.0 }
            
            /* Scale health bar between 0.0 -> 1.0 e.g 0 -> 100% */
            healthBar.xScale = health
        }
    }
    
    var score: Int = 0 {
        didSet {
            scoreLabel.text = String(score)
        }
    }
    
    override func didMoveToView(view: SKView) {
        /* Connect game objects */
        sushiBasePiece = childNodeWithName("sushiBasePiece") as! SushiPiece
        /* Setup chopstick connections */
        sushiBasePiece.connectChopsticks()
        
        /* Connect game objects */
        character = childNodeWithName("character") as! Character
        
        healthBar = childNodeWithName("healthBar") as! SKSpriteNode
        
        /* UI game objects */
        playButton = childNodeWithName("playButton") as! MSButtonNode
        
        scoreLabel = childNodeWithName("scoreLabel") as! SKLabelNode
        
        /* Manually stack the start of the tower */
        addTowerPiece(.None)
        addTowerPiece(.Right)
        
        /* Randomize tower to just outside of the screen */
        addRandomPieces(10)
        
        /* Setup play button selection handler */
        playButton.selectedHandler = {
            
            /* Start game */
            self.state = .Ready
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
            /* Called when a touch begins */
        
            /* Game not ready to play */
            if state == .GameOver || state == .Title { return }
        
            /* Game begins on first touch */
            if state == .Ready {
                state = .Playing
            }
            
            for touch in touches {
                /* Get touch position in scene */
                let location = touch.locationInNode(self)
                
                /* Was touch on left/right hand side of screen? */
                if location.x > size.width / 2 {
                    character.side = .Right
                } else {
                    character.side = .Left
                }
                
                /* Grab sushi piece on top of the base sushi piece, it will always be 'first' */
                let firstPiece = sushiTower.first as SushiPiece!
                
                /* Check character side against sushi piece side (this is the death collision check)*/
                if character.side == firstPiece.side {
                    
                    /* Drop all the sushi pieces down a place (visually) */
                    for node:SushiPiece in sushiTower {
                        node.runAction(SKAction.moveBy(CGVector(dx: 0, dy: -55), duration: 0.10))
                    }
                    
                    gameOver()
                    
                    /* No need to continue as player dead */
                    return
                }
                
                /* Increment Health */
                health += 0.1
                
                /* Increment Score */
                score += 1
                
                /* Remove from sushi tower array */
                sushiTower.removeFirst()
                
                /* Animate the punched sushi piece */
                firstPiece.flip(character.side)
                
                /* Add a new sushi piece to the top of the sushi tower */
                addRandomPieces(1)
                
                /* Drop all the sushi pieces down one place */
                for node:SushiPiece in sushiTower {
                    node.runAction(SKAction.moveBy(CGVector(dx: 0, dy: -55), duration: 0.10))
                    
                    /* Reduce zPosition to stop zPosition climbing over UI */
                    node.zPosition -= 1
                }
        }
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        if state != .Playing { return }
        
        /* Decrease Health */
        health -= 0.01
        
        /* Has the player run out of health? */
        if health < 0 { gameOver() }
    }
    
    func addTowerPiece(side: Side) {
        /* Add a new sushi piece to the sushi tower */
    
        /* Copy original sushi piece */
        let newPiece = sushiBasePiece.copy() as! SushiPiece
        newPiece.connectChopsticks()
    
        /* Access last piece properties */
        let lastPiece = sushiTower.last
    
        /* Add on top of last piece, default on first piece */
        let lastPosition = lastPiece?.position ?? sushiBasePiece.position
        newPiece.position = lastPosition + CGPoint(x: 0, y: 55)
    
        /* Increment Z to ensure it's on top of the last piece, default on first piece*/
        let lastZPosition = lastPiece?.zPosition ?? sushiBasePiece.zPosition
        newPiece.zPosition = lastZPosition + 1
    
        /* Set side */
        newPiece.side = side
    
        /* Add sushi to scene */
        addChild(newPiece)
    
        /* Add sushi piece to the sushi tower */
        sushiTower.append(newPiece)
    }
    
    func addRandomPieces(total: Int) {
        /* Add random sushi pieces to the sushi tower */
        
        for _ in 1...total {
            
            /* Need to access last piece properties */
            let lastPiece = sushiTower.last as SushiPiece!
            
            /* Need to ensure we don't create impossible sushi structures */
            if lastPiece.side != .None {
                addTowerPiece(.None)
            } else {
                
                /* Random Number Generator */
                let rand = CGFloat.random(min: 0, max: 1.0)
                
                if rand < 0.45 {
                    /* 45% Chance of a left piece */
                    addTowerPiece(.Left)
                } else if rand < 0.9 {
                    /* 45% Chance of a right piece */
                    addTowerPiece(.Right)
                } else {
                    /* 10% Chance of an empty piece */
                    addTowerPiece(.None)
                }
            }
        }
    }
    
    func gameOver() {
        /* Game over! */
        
        state = .GameOver
        
        /* Turn all the sushi pieces red*/
        for node:SushiPiece in sushiTower {
            node.runAction(SKAction.colorizeWithColor(UIColor.redColor(), colorBlendFactor: 1.0, duration: 0.50))
        }
        
        /* Make the player turn red */
        character.runAction(SKAction.colorizeWithColor(UIColor.redColor(), colorBlendFactor: 1.0, duration: 0.50))
        
        /* Change play button selection handler */
        playButton.selectedHandler = {
            
            /* Grab reference to the SpriteKit view */
            let skView = self.view as SKView!
            
            /* Load Game scene */
            let scene = GameScene(fileNamed:"GameScene") as GameScene!
            
            /* Ensure correct aspect mode */
            scene.scaleMode = .AspectFill
            
            /* Restart GameScene */
            skView.presentScene(scene)
        }
    }
    
   }
