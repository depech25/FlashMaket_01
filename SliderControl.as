package {
    import flash.display.MovieClip;
    import flash.events.MouseEvent;
    import flash.events.Event;
    import flash.geom.Point;
    import flash.text.TextField;

    public class SliderControl extends MovieClip {
        public var thumb:MovieClip;
        public var track:MovieClip;

        public var minValue:Number = 40;
        public var maxValue:Number = 201;
        public var value:Number = 201;

        public var sliderEdge:Number = 0;

        private var isDragging:Boolean = false;
        private var lastValue:Number = -9999;

        public static const VALUE_CHANGED:String = "valueChanged";

        public var SliderText:TextField;

        public function SliderControl() {
            addEventListener(Event.ADDED_TO_STAGE, onAdded);
        }

        private function onAdded(e:Event):void {
            removeEventListener(Event.ADDED_TO_STAGE, onAdded);

            if (!thumb || !track) {
                trace("[SliderControl] ❌ thumb или track отсутствует!");
                return;
            }

            if (!SliderText) {
                SliderText = this.getChildByName("SliderText") as TextField;
            }

            updateSliderText(value);

            thumb.buttonMode = true;

            thumb.addEventListener(MouseEvent.MOUSE_DOWN, onStartDrag);
            stage.addEventListener(MouseEvent.MOUSE_UP, onStopDrag);

            trace("[SliderControl] ✅ Инициализация завершена");
        }

        private function onStartDrag(e:MouseEvent):void {
            isDragging = true;
            trace("[SliderControl] ▶️ НАЧАЛО drag");

            stage.addEventListener(MouseEvent.MOUSE_MOVE, onDragging);
        }

        private function onStopDrag(e:MouseEvent):void {
            if (isDragging) {
                trace("[SliderControl] ⏹ ОКОНЧАНИЕ drag");
            }

            isDragging = false;
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, onDragging);
        }

        private function onDragging(e:MouseEvent):void {
            if (!isDragging) return;

            var globalX:Number = stage.mouseX;
            var local:Point = this.globalToLocal(new Point(globalX, 0));
            var mouseXRelative:Number = local.x;

            var leftLimit:Number = track.x - (track.width / 2) + sliderEdge;
            var rightLimit:Number = track.x + (track.width / 2) - sliderEdge;

            if (rightLimit < leftLimit) {
                var temp:Number = leftLimit;
                leftLimit = rightLimit;
                rightLimit = temp;
            }

            var clampedX:Number = Math.max(leftLimit, Math.min(mouseXRelative, rightLimit));
            thumb.x = clampedX;

            trace("[SliderControl] 🖱 mouseX: global=" + globalX + "  local=" + mouseXRelative);
            trace("[SliderControl] 📍 thumb.x=" + thumb.x + "  left=" + leftLimit + "  right=" + rightLimit);

            var percent:Number = (thumb.x - leftLimit) / (rightLimit - leftLimit);
            value = minValue + percent * (maxValue - minValue);

            updateSliderText(value);

            if (Math.abs(value - lastValue) > 0.01) {
                lastValue = value;
                trace("[SliderControl] 🔄 VALUE_CHANGED → " + value);
                dispatchEvent(new Event(VALUE_CHANGED));
            }
        }

        public function setValue(newValue:Number):void {
            value = Math.max(minValue, Math.min(newValue, maxValue));
            lastValue = value;

            var leftLimit:Number = track.x - (track.width / 2) + sliderEdge;
            var rightLimit:Number = track.x + (track.width / 2) - sliderEdge;

            if (rightLimit < leftLimit) {
                var temp:Number = leftLimit;
                leftLimit = rightLimit;
                rightLimit = temp;
            }

            var percent:Number = (value - minValue) / (maxValue - minValue);
            thumb.x = leftLimit + percent * (rightLimit - leftLimit);

            updateSliderText(value);

            trace("[SliderControl] 📦 Программно установлено значение=" + value);
            dispatchEvent(new Event(VALUE_CHANGED));
        }

        private function updateSliderText(val:Number):void {
            if (SliderText) {
                SliderText.text = String(Math.round(val));
            } else {
                trace("[SliderControl] ⚠️ SliderText не найден для отображения значения");
            }
        }
    }
}
