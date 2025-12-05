package {
    import flash.display.MovieClip;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.utils.clearInterval;
    import flash.utils.setInterval;

    public class AnimatedClip extends MovieClip {

        private var maskSprite:Sprite;
        private var isShown:Boolean = false;
        private var animating:Boolean = false;

        private var animInterval:uint;
        private var totalDuration:int = 50; // длительность анимации в мс
        private var frameInterval:int = 10;  // интервал в мс между шагами
        private var steps:int;               // количество шагов анимации
        private var currentStep:int = 0;
        private var stepWidth:Number = 0;

        private var maskWidth:Number = 0;

        public function AnimatedClip() {
            super();
            addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        }

        private function onAddedToStage(e:Event):void {
            removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);

            if (!this.hasOwnProperty("Sprite_Rectangle") || !(this["Sprite_Rectangle"] is MovieClip)) {
                throw new Error("Sprite_Rectangle не найден! Проверь имя вложенного MovieClip в Flash IDE.");
            }

            var spriteRectangle:MovieClip = this["Sprite_Rectangle"] as MovieClip;
            spriteRectangle.alpha = 0;

            maskSprite = new Sprite();
            addChild(maskSprite);

            spriteRectangle.mask = maskSprite;

            this.addEventListener(MouseEvent.CLICK, onClick);

            // Вычисляем количество шагов и шаг по ширине
            steps = Math.ceil(totalDuration / frameInterval);
            stepWidth = spriteRectangle.width / steps;
        }

        private function onClick(e:MouseEvent):void {
            if (animating) return;

            var spriteRectangle:MovieClip = this["Sprite_Rectangle"] as MovieClip;

            if (animInterval) {
                clearInterval(animInterval);
                animInterval = 0;
            }

            animating = true;
            currentStep = 0;

            if (!isShown) {
                spriteRectangle.alpha = 1;
                maskWidth = 0;
                maskSprite.graphics.clear();
                animInterval = setInterval(showStep, frameInterval);
            } else {
                maskWidth = spriteRectangle.width;
                animInterval = setInterval(hideStep, frameInterval);
            }
        }

        private function showStep():void {
            var spriteRectangle:MovieClip = this["Sprite_Rectangle"] as MovieClip;

            currentStep++;
            maskWidth = stepWidth * currentStep;

            if (currentStep >= steps) {
                maskWidth = spriteRectangle.width;
                clearInterval(animInterval);
                animInterval = 0;
                isShown = true;
                animating = false;
            }

            drawMask(maskWidth);
        }

        private function hideStep():void {
            var spriteRectangle:MovieClip = this["Sprite_Rectangle"] as MovieClip;

            currentStep++;
            maskWidth = spriteRectangle.width - stepWidth * currentStep;

            if (currentStep >= steps) {
                maskWidth = 0;
                clearInterval(animInterval);
                animInterval = 0;
                isShown = false;
                spriteRectangle.alpha = 0;
                animating = false;
            }

            drawMask(maskWidth);
        }

        private function drawMask(width:Number):void {
            var spriteRectangle:MovieClip = this["Sprite_Rectangle"] as MovieClip;

            maskSprite.graphics.clear();
            maskSprite.graphics.beginFill(0x000000);
            maskSprite.graphics.drawRect(spriteRectangle.x, spriteRectangle.y, width, spriteRectangle.height);
            maskSprite.graphics.endFill();
        }
    }
}
