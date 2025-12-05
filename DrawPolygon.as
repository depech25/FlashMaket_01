package {
    import flash.display.Sprite;
    import flash.display.Graphics;
    import flash.events.Event;

    /**
     * DrawPolygon — отрисовывает полигон по точкам,
     * заданным в процентах от ширины/высоты контейнера.
     */
    public class DrawPolygon extends Sprite {

        private var percentPoints:Array; // [ [0.1,0.2], [0.3,0.5], ... ]
        private var lineColor:uint = 0xFF0000;
        private var fillColor:uint = 0x00FF00;
        private var fillAlpha:Number = 0.3;
        private var lineThickness:Number = 2;

        public function DrawPolygon(points:Array,
                                    lineColor:uint = 0xFF0000,
                                    fillColor:uint = 0x00FF00,
                                    fillAlpha:Number = 0.3,
                                    lineThickness:Number = 2)
        {
            this.percentPoints = points;
            this.lineColor = lineColor;
            this.fillColor = fillColor;
            this.fillAlpha = fillAlpha;
            this.lineThickness = lineThickness;

            this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
        }

        private function onAdded(e:Event):void {
            this.removeEventListener(Event.ADDED_TO_STAGE, onAdded);
            draw();
        }

        /// Перерисовать фигуру
        public function draw():void {
            if (!stage || !percentPoints || percentPoints.length < 3) return;

            var g:Graphics = graphics;
            g.clear();

            g.lineStyle(lineThickness, lineColor);
            g.beginFill(fillColor, fillAlpha);

            // конвертация процентов в координаты
            var first:Array = percentToPixel(percentPoints[0]);
            g.moveTo(first[0], first[1]);

            for (var i:int = 1; i < percentPoints.length; i++) {
                var p:Array = percentToPixel(percentPoints[i]);
                g.lineTo(p[0], p[1]);
            }

            // замыкаем
            g.lineTo(first[0], first[1]);

            g.endFill();
        }

        /// Конвертировать [pxPercent, pyPercent] → [actualX, actualY]
        private function percentToPixel(p:Array):Array {
            var x:Number = p[0] * this.stage.stageWidth;
            var y:Number = p[1] * this.stage.stageHeight;
            return [x, y];
        }
    }
}
