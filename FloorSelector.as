package {
    import flash.display.MovieClip;
    import flash.display.DisplayObject;
    import flash.display.DisplayObjectContainer;
    import flash.events.MouseEvent;
    import flash.events.Event;

    public class FloorSelector extends MovieClip {
        private var buttons:Array;
        private var _applyScheduled:Boolean = false;
        private var _retryCount:int = 0;
        private var _applyRemaining:int = 0; // сколько раз подряд применяем после успешного поиска панели

        public function FloorSelector() {
            super();
            trace("[FloorSelector] ? Конструктор вызван");

            buttons = [];

            // Имена кнопок TglBtn_02..TglBtn_08
            for (var i:int = 2; i <= 8; i++) {
                var btnName:String = "TglBtn_0" + i;
                var btn:ToggleButton = this.getChildByName(btnName) as ToggleButton;

                if (btn) {
                    trace("[FloorSelector] ? Найдена кнопка: " + btnName);
                    buttons.push(btn);
                    btn.addEventListener(MouseEvent.CLICK, onButtonClick);
                    btn.buttonMode = true;
                    btn.mouseChildren = false;
                } else {
                    trace("[FloorSelector] ? Кнопка " + btnName + " не найдена!");
                }
            }

            // Отложенное выполнение, чтобы сцена и родитель были готовы
            this.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        }

        private function onAddedToStage(e:Event):void {
            this.removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
            trace("[FloorSelector] ? onAddedToStage, определяем активную кнопку");

            // Определяем активный этаж по текущему кадру родителя
            var currentFrame:int = 1;
            if (this.parent && this.parent is MovieClip) {
                currentFrame = MovieClip(this.parent).currentFrame;
                trace("[FloorSelector] ? Родитель на кадре: " + currentFrame);
            } else {
                trace("[FloorSelector] ? Родитель не MovieClip");
            }

            updateStateByFrame(currentFrame);
            scheduleFilterApply();
        }

        private function updateStateByFrame(frameNum:int):void {
            trace("[FloorSelector] ? updateStateByFrame: " + frameNum);

            var activeBtnName:String = "TglBtn_0" + frameNum;
            var activeFound:Boolean = false;

            for each (var btn:ToggleButton in buttons) {
                if (btn.name == activeBtnName) {
                    trace("[FloorSelector] ? Активная кнопка: " + btn.name);
                    btn.setState(true);
                    btn.setEnabled(false);
                    activeFound = true;
                } else {
                    trace("[FloorSelector] ? Неактивная кнопка: " + btn.name);
                    btn.setState(false);
                    btn.setEnabled(true);
                }
            }

            if (!activeFound) {
                trace("[FloorSelector] ? Нет кнопки для кадра " + frameNum);
            }
        }

        private function onButtonClick(e:MouseEvent):void {
            var clickedBtn:ToggleButton = e.currentTarget as ToggleButton;
            trace("[FloorSelector] ? Клик по кнопке: " + clickedBtn.name);

            // Переключаем кнопки
            for each (var btn:ToggleButton in buttons) {
                if (btn == clickedBtn) {
                    btn.setState(true);
                    btn.setEnabled(false);
                } else {
                    btn.setState(false);
                    btn.setEnabled(true);
                }
            }

            // Переходим на соответствующий кадр
            var frameStr:String = clickedBtn.name.substr(clickedBtn.name.length - 2);
            var frameNum:int = int(frameStr);
            trace("[FloorSelector] ? Переход на кадр: " + frameNum);

            if (this.parent && this.parent is MovieClip) {
                MovieClip(this.parent).gotoAndStop(frameNum);
                trace("[FloorSelector] ? Кадр изменён");
                scheduleFilterApply();
            } else {
                trace("[FloorSelector] ? Родитель не MovieClip");
            }
        }

        private function scheduleFilterApply():void {
            if (_applyScheduled) return;
            _applyScheduled = true;
            _retryCount = 0;
            _applyRemaining = 2; // применяем фильтр несколько кадров подряд после смены этажа
            addEventListener(Event.ENTER_FRAME, onApplyFiltersNextFrame);
        }

        private function onApplyFiltersNextFrame(e:Event):void {
            _retryCount++;

            var panel:ApartmentFilterPanel = resolveFilterPanel();
            if (panel && panel.stage) {
                try {
                    trace("[FloorSelector] ? Запускаем повторное применение фильтров после смены кадра (оставшихся применений: " + _applyRemaining + ")");
                    panel.suppressLightingUntilUserChange(); // при автоприменении подсветку не отправляем
                    panel.applyApartmentFilters();
                    _applyRemaining--;
                    if (_applyRemaining <= 0) {
                        removeEventListener(Event.ENTER_FRAME, onApplyFiltersNextFrame);
                        _applyScheduled = false;
                    }
                } catch (err:Error) {
                    trace("[FloorSelector] ! Ошибка при applyApartmentFilters: " + err.message + "\n" + err.getStackTrace());
                    removeEventListener(Event.ENTER_FRAME, onApplyFiltersNextFrame);
                    _applyScheduled = false;
                }
            } else if (_retryCount > 5) {
                removeEventListener(Event.ENTER_FRAME, onApplyFiltersNextFrame);
                _applyScheduled = false;
                trace("[FloorSelector] ? ApartmentFilterPanel не найден для повторного применения фильтра (после нескольких попыток)");
            } else {
                // ждем следующий кадр, возможно панель ещё не на сцене
                trace("[FloorSelector] ? Панель пока не найдена, пробуем ещё. Попытка " + _retryCount);
            }
        }

        private function resolveFilterPanel():ApartmentFilterPanel {
            // Пробуем найти панель в родителе или на сцене по типу и/или имени
            if (this.parent && this.parent is DisplayObjectContainer) {
                var p:DisplayObjectContainer = this.parent as DisplayObjectContainer;
                var panel:ApartmentFilterPanel = p.getChildByName("apartmentFilterPanel") as ApartmentFilterPanel;
                if (panel) return panel;
                panel = findPanelRecursive(p);
                if (panel) return panel;
            }
            if (stage) {
                var st:DisplayObjectContainer = stage as DisplayObjectContainer;
                var direct:ApartmentFilterPanel = st.getChildByName("apartmentFilterPanel") as ApartmentFilterPanel;
                if (direct) return direct;
                return findPanelRecursive(st);
            }
            return null;
        }

        private function findPanelRecursive(container:DisplayObjectContainer):ApartmentFilterPanel {
            if (!container) return null;
            var count:int = container.numChildren;
            for (var i:int = 0; i < count; i++) {
                var child:DisplayObject = container.getChildAt(i);
                if (child is ApartmentFilterPanel) {
                    return child as ApartmentFilterPanel;
                }
                if (child is DisplayObjectContainer) {
                    var found:ApartmentFilterPanel = findPanelRecursive(child as DisplayObjectContainer);
                    if (found) return found;
                }
            }
            return null;
        }
    }
}
