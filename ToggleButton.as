package {
    import flash.display.MovieClip;
    import flash.events.MouseEvent;
    import flash.events.Event;

    public class ToggleButton extends MovieClip {
        public var state:Boolean = false;

        public static const TOGGLE_CHANGED:String = "ToggleChanged";

        private var _enabled:Boolean = true; // активна ли кнопка

        public function ToggleButton() {
            super();
            trace("[ToggleButton] ▶ Конструктор вызван");

            stop(); // кадры ещё не готовы — просто стопаем

            this.buttonMode = true;
            this.mouseChildren = false;

            this.addEventListener(MouseEvent.CLICK, onClick);

            // ВАЖНО: ждем, пока кнопка окажется на сцене
            this.addEventListener(Event.ADDED_TO_STAGE, onAdded);

            trace("[ToggleButton] ⏳ Ожидаем ADDED_TO_STAGE");
        }

        private function onAdded(e:Event):void {
            this.removeEventListener(Event.ADDED_TO_STAGE, onAdded);
            trace("[ToggleButton] 🎉 ADDED_TO_STAGE → выполняем первый updateVisualState()");
            //updateVisualState();
        }

        private function onClick(e:MouseEvent):void {
            if (!_enabled) {
                trace("[ToggleButton] ❌ Кнопка отключена, клики игнорируются");
                return;
            }

            state = !state;
            trace("[ToggleButton] 🔁 Клик. Новое состояние: " + state);

            updateVisualState();
            dispatchEvent(new Event(TOGGLE_CHANGED));
        }

        private function updateVisualState():void {
            if (state) {
                trace("[ToggleButton] 🎨 Включено (кадр 2)");
                gotoAndStop(2);
            } else {
                trace("[ToggleButton] 🎨 Выключено (кадр 1)");
                gotoAndStop(1);
            }
        }

        public function setState(value:Boolean):void {
            trace("[ToggleButton] ⚙ setState → " + value);
			if (state != value){
				state = value;
				updateVisualState();
			}
        }

        public function getState():Boolean {
            return state;
        }

        public function setEnabled(value:Boolean):void {
            trace("[ToggleButton] ⚙ setEnabled → " + value);
            _enabled = value;
        }

        public function getEnabled():Boolean {
            return _enabled;
        }
    }
}
