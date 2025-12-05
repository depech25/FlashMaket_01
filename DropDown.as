package  {
    import flash.display.MovieClip;
    import flash.events.MouseEvent;
    import flash.events.Event;

    public class DropDown extends MovieClip {

        public static const FILTER_CHANGED:String = "DropDownFilterChanged";

        private var _isOpen:Boolean = false;
        private var _toggleStates:Object = {};
        private var _wiredToggles:Array = [];

        public var closedHeight:int = 150;
        public var openHeight:int = 606;

        public function DropDown() {
            super();

            stop(); // Всегда останавливаем анимацию

            // На каждом кадре должен быть клип btn
            addFrameScript(0, onFrame1);
            addFrameScript(1, onFrame2);

            // Принудительно ставим кадр в закрытое состояние,
            // чтобы визуальная высота совпадала с currentHeight при создании
            gotoAndStop(_isOpen ? 2 : 1);

            // Когда клип попадает на сцену - подхватываем toggle-кнопки
            addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        }

        private function onAddedToStage(e:Event):void {
            removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
            wireToggleButtonsForCurrentFrame();
            dispatchEvent(new Event(FILTER_CHANGED, true)); // стартовое состояние
        }

        private function onFrame1():void {
            if (btn)
                btn.addEventListener(MouseEvent.CLICK, toggle);
        }

        private function onFrame2():void {
            if (btn)
                btn.addEventListener(MouseEvent.CLICK, toggle);
        }

        private function toggle(e:MouseEvent):void {
            // Перед переключением кадра сохраняем текущее состояние кнопок
            rememberToggleStates();

            _isOpen = !_isOpen;

            if (_isOpen)
                gotoAndStop(2);
            else
                gotoAndStop(1);

            // После смены кадра подхватываем новые инстансы кнопок и восстанавливаем их состояние
            wireToggleButtonsForCurrentFrame();

            dispatchEvent(new Event("STATE_CHANGED", true));
            dispatchEvent(new Event(FILTER_CHANGED, true));
        }

        public function get isOpen():Boolean { return _isOpen; }

        public function get currentHeight():int {
            return _isOpen ? openHeight : closedHeight;
        }

        public function getToggleStates():Object {
            var copy:Object = {};
            for (var key:String in _toggleStates) {
                copy[key] = _toggleStates[key];
            }
            return copy;
        }

        // Находит ToggleButton на текущем кадре, восстанавливает их состояние и подписывается на изменения
        private function wireToggleButtonsForCurrentFrame():void {
            // Отписываемся от старых инстансов
            for each (var oldTgl:ToggleButton in _wiredToggles) {
                if (oldTgl) {
                    oldTgl.removeEventListener(ToggleButton.TOGGLE_CHANGED, onToggleChanged);
                }
            }
            _wiredToggles = [];

            // Обходим детей текущего кадра
            var i:int;
            for (i = 0; i < numChildren; i++) {
                var tgl:ToggleButton = getChildAt(i) as ToggleButton;
                if (!tgl || !tgl.name) {
                    continue;
                }

                // Восстанавливаем сохранённое состояние, если оно было
                if (_toggleStates.hasOwnProperty(tgl.name)) {
                    tgl.setState(_toggleStates[tgl.name]);
                } else {
                    _toggleStates[tgl.name] = tgl.getState();
                }

                tgl.addEventListener(ToggleButton.TOGGLE_CHANGED, onToggleChanged);
                _wiredToggles.push(tgl);
            }
        }

        private function onToggleChanged(e:Event):void {
            var tgl:ToggleButton = e.currentTarget as ToggleButton;
            if (tgl && tgl.name) {
                _toggleStates[tgl.name] = tgl.getState();
                // Сообщаем наверх (FiltersBar) о новых фильтрах
                dispatchEvent(new Event(FILTER_CHANGED, true));
            }
        }

        // Сохраняем состояния всех toggle-кнопок текущего кадра
        private function rememberToggleStates():void {
            var i:int;
            for (i = 0; i < numChildren; i++) {
                var tgl:ToggleButton = getChildAt(i) as ToggleButton;
                if (tgl && tgl.name) {
                    _toggleStates[tgl.name] = tgl.getState();
                }
            }
        }
    }
}
