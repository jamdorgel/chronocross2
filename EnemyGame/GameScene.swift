import SpriteKit
import GameplayKit

struct PhysicsCategory{
    static let none: UInt32 = 0
    static let all: UInt32 = UInt32.max
    static let monster: UInt32 = 0x1 << 1
    static let projectile: UInt32 = 0x1 << 2
    static let player: UInt32 = 0x1 << 3
    static let arm: UInt32 = 0x1 << 4
}

func +(left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func -(left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func *(point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func /(point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
func sqrt(a: CGFloat) -> CGFloat {
    return CGFloat(sqrtf(Float(a)))
}
#endif

extension CGPoint {
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    func normalized() -> CGPoint {
        return self / length()
    }
}

class GameScene: SKScene {
    
    let player = SKSpriteNode(imageNamed: "player")
    let arm = SKSpriteNode(imageNamed: "sword")
    var monstersDestroyed = 0
    override func didMove(to view: SKView) {
    backgroundColor = SKColor.yellow
        player.position = CGPoint(x: size.width * 0.2, y: size.height * 0.5 )
        player.zPosition = 55
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody?.isDynamic = true
        player.physicsBody?.categoryBitMask = PhysicsCategory.player
        player.physicsBody?.contactTestBitMask = PhysicsCategory.monster
        player.physicsBody?.collisionBitMask = PhysicsCategory.none
        player.physicsBody?.usesPreciseCollisionDetection = true
        
        addChild(player)
        
        arm.position = CGPoint(x: player.position.x + player.frame.width + 10, y: player.position.y + player.frame.height / 2)
        arm.zPosition = 75
        arm.physicsBody = SKPhysicsBody(circleOfRadius: arm.size.width / 2)
        arm.physicsBody?.isDynamic = true
        arm.physicsBody?.categoryBitMask = PhysicsCategory.arm // part of monster physics group
        arm.physicsBody?.contactTestBitMask = PhysicsCategory.monster // collide with projectle
        arm.physicsBody?.collisionBitMask = PhysicsCategory.none // don't bounce off of any sprite -> none
        arm.physicsBody?.usesPreciseCollisionDetection = true
        
        addChild(arm)
        
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        addMonster()
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run(addMonster),
                SKAction.wait(forDuration: 1.0)
               ])
                ))
        let backgroundMusic = SKAudioNode(fileNamed: "backgroundmusic.mp3")
        backgroundMusic.autoplayLooped = true
        addChild(backgroundMusic)
    }
    
    func random() -> CGFloat {
    return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    func addMonster(){
        let monster = SKSpriteNode(imageNamed: "monster")
        let actualY = random(min: monster.size.height / 2, max: size.height -
        monster.size.height / 2)
        monster.position = CGPoint(x: size.width + monster.size.width / 2 , y:
        actualY)
        monster.physicsBody = SKPhysicsBody(rectangleOf: monster.size)
        monster.physicsBody?.isDynamic = true
        monster.physicsBody?.categoryBitMask = PhysicsCategory.monster
        monster.physicsBody?.contactTestBitMask = PhysicsCategory.arm
        monster.physicsBody?.collisionBitMask = PhysicsCategory.none
        monster.physicsBody?.usesPreciseCollisionDetection = true
        addChild(monster)
        
        let actualDuration = random(min: CGFloat(2.0),  max: CGFloat(4.0))
        let actionMove = SKAction.move(to: CGPoint(x: -monster.size.width / 2, y:
        actualY), duration: TimeInterval(actualDuration))
        let actionMoveDone = SKAction.removeFromParent()
        monster.run(SKAction.sequence([actionMove, actionMoveDone]))
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else{
            return
        }
        run(SKAction.playSoundFileNamed("swordsound.mp3", waitForCompletion: false))
        let touchLocation = touch.location(in: self)
        
        let offset = touchLocation - player.position
//        if offset.x < 0 {return}
        
        let direction = offset.normalized()
        let shootAmount = direction * 100
        let realDest = shootAmount + player.position
        let actionMove = SKAction.move(to: realDest, duration: 2.0)
        let actionMoveDone = SKAction.removeFromParent()
        player.run(SKAction.sequence([actionMove]))

    }
    
    func projectileDidCollideWithMonster(projectile : SKSpriteNode, monster: SKSpriteNode){
        print("monster got hit! yay!")
        
        run(SKAction.playSoundFileNamed("swordsound.mp3", waitForCompletion: false))
        let realDest = CGPoint(x: player.position.x + player.frame.width + 20, y: player.position.y + player.frame.height / 2)
        let finalDest = CGPoint(x: player.position.x + player.frame.width + 10, y: player.position.y + player.frame.height / 2)
        let actionMove = SKAction.move(to: realDest, duration: 0.3)
        let actionMoveDone = SKAction.move(to: finalDest, duration: 0.2)
        arm.run(SKAction.sequence([actionMove, actionMoveDone]))
        monster.removeFromParent()
        monstersDestroyed += 1
        if monstersDestroyed > 9 {
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            let gameOverScene = GameOverScene(size: self.size, won: true)
            view?.presentScene(gameOverScene, transition: reveal)
        }
    }
    
    
    
    func playerDidCollideWithMonster(player: SKSpriteNode, monster:SKSpriteNode){
        print("oh no! player got hit!")
        
        monster.removeFromParent()
        
        let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
        let gameOverScene = GameOverScene(size: self.size, won: false)
        view?.presentScene(gameOverScene, transition: reveal)
    }
    
    override func update(_ currentTime: TimeInterval) {
        arm.position = CGPoint(x: player.position.x + player.frame.width + 10, y: player.position.y + player.frame.height / 2)
        
    }
}

extension GameScene: SKPhysicsContactDelegate{
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody : SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        }
        else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        if ((firstBody.categoryBitMask & PhysicsCategory.monster) != 0)
            && ((secondBody.categoryBitMask & PhysicsCategory.player) != 0){
            if let monster = firstBody.node as? SKSpriteNode,
                let player = secondBody.node as? SKSpriteNode {
                playerDidCollideWithMonster(player: player, monster: monster)
            }
        }
        else  if ((firstBody.categoryBitMask & PhysicsCategory.monster) != 0)
            && ((secondBody.categoryBitMask & PhysicsCategory.arm) != 0) {
            if let monster = firstBody.node as? SKSpriteNode,
                let arm = secondBody.node as? SKSpriteNode {
                projectileDidCollideWithMonster(projectile: arm, monster: monster)
            }
        }
    }
}
