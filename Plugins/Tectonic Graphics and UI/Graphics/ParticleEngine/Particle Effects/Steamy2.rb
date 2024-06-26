class Particle_Engine::Steamy2 < ParticleEffect_Event
    def initialize(event,viewport)
        super
        setParameters([
            0, # Random hue
            0, # fade
            20, # max particles
            0, # hue
            5, # slowdown
            -Graphics.height, # ytop
            Graphics.height, # ybottom
            0, # xleft
            Graphics.width, # xright
            0, # xgravity
            -0.5, # ygravity
            0, # xoffset
            0, # yoffset
            3, # opacity var
            5 # original opacity
            ])
        @opacityMult = 0.2
        @huerange = 10
        @cullOffscreen = false
        @movesleftright = false
        @movesupdown = false
        @radius = 50
        @rad2 = @radius * @radius
        @maxOpacity = 50

        initParticles("steam",100)
    end

    def resetParticle(i)
        randomRad = Math.sqrt(rand(@rad2))
        randomAngle = rand(360)
        xRand = Math.cos(randomAngle) * randomRad
        xRand *= 1.5
        yRand = Math.sin(randomAngle) * randomRad
        @particles[i].x = @startingx + @xoffset + xRand
        @particles[i].y = @startingy + @yoffset + yRand
        @particlex[i] = xRand
        @particley[i] = yRand
        @particles[i].state = 0

        hue = @hue + rand(@huerange) - @huerange / 2
        hue -= 360 if @hue >= 360
        hue += 360 if @hue <= 0

        @particles[i].bitmap = loadBitmap(@filename, hue)
    end

    def resetOpacity(i)
        @opacity[i] = 1
        @particles[i].state = 0
    end

    def initializeParticle(i)
        @opacity[i] = rand(@maxOpacity)
        @particles[i].angle = rand(360)
    end

    def changeOpacity(i)
        if @particles[i].state == 0
            @opacity[i] += 1
            if @opacity[i] >= @maxOpacity
                @particles[i].state = 1
            end
        else
            @opacity[i] -= 1
        end
    end

    def xExtent
        return @radius * 2
    end

    def yExtent
        return @radius * 2
    end
end