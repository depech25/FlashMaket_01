package  {
    import flash.display.MovieClip;
    import flash.events.Event;

    public class FiltersBar extends MovieClip {

        public var filterPanel:ApartmentFilterPanel; // Ссылка на панель фильтров (устанавливается извне или ищется по имени)
        private var items:Array = [];

        public function FiltersBar() {
            super();

            // Предполагаем, что в Animate на сцене:
            // dropdown1, dropdown2, dropdown3 ...
            items = [dropdown1, dropdown2, dropdown3];

            for each (var dd:DropDown in items) {
                if (!dd) continue;
                dd.addEventListener("STATE_CHANGED", onStateChanged);
                dd.addEventListener(DropDown.FILTER_CHANGED, onDropDownFilterChanged);
            }

            layout();
            addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        }

        private function onAddedToStage(e:Event):void {
            removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
            forwardFilters(false);
        }

        private function onStateChanged(e:Event):void {
            layout();
        }

        private function onDropDownFilterChanged(e:Event):void {
            forwardFilters(true);
        }

        private function layout():void {
            var currentY:int = 0;

            // Расставляем меню друг под другом
            for each (var dd:DropDown in items) {
                if (!dd) continue;
                dd.y = currentY;
                currentY += dd.currentHeight;
            }
        }

        private function forwardFilters(userInitiated:Boolean = false):void {
            if (!filterPanel) {
                // Если FiltersBar вложен внутрь ApartmentFilterPanel
                if (parent is ApartmentFilterPanel) {
                    filterPanel = parent as ApartmentFilterPanel;
                }

                // Пытаемся найти панель по имени, если её не установили извне
                if (!filterPanel && parent) {
                    filterPanel = parent.getChildByName("apartmentFilterPanel") as ApartmentFilterPanel;
                }
                if (!filterPanel && stage) {
                    filterPanel = stage.getChildByName("apartmentFilterPanel") as ApartmentFilterPanel;
                }
            }

            var filters:Object = collectFilters();

            if (filterPanel) {
                filterPanel.applyDropdownFilters(filters, userInitiated);
            } else {
                trace("[FiltersBar] Нет ссылки на ApartmentFilterPanel");
            }
        }

        // Если нужно задать ссылку вручную из кода на сцене
        public function setFilterPanel(panel:ApartmentFilterPanel):void {
            filterPanel = panel;
            forwardFilters(false);
        }

        private function collectFilters():Object {
            var status:Array = [];
            var type:Array = [];
            var square:Array = [];

            for each (var dd:DropDown in items) {
                if (!dd) continue;
                var states:Object = dd.getToggleStates();
                if (!states) continue;

                // status
                if (states["tgl_Available"]) pushUnique(status, "Available");
                if (states["tgl_Reserved"])  pushUnique(status, "Reserved");
                if (states["tgl_Occupied"])  pushUnique(status, "Occupied");
                if (states["tgl_Closed"])    pushUnique(status, "Closed for sale");

                // type
                if (states["tgl_Extency"])   pushUnique(type, "Extency Superior");
                if (states["tgl_Emerald"])   pushUnique(type, "Emerald");
                if (states["tgl_Family"])    pushUnique(type, "Family");
                if (states["tgl_Penthouse"]) pushUnique(type, "Penthouse");

                // square
                if (states["tgl_55m"])  pushRangeUnique(square, 55, 92);
                if (states["tgl_92m"])  pushRangeUnique(square, 92, 140);
                if (states["tgl_140m"]) pushRangeUnique(square, 140, 251);
            }

            return {
                status: status,
                type: type,
                square: square
            };
        }

        private function pushUnique(arr:Array, value:String):void {
            if (arr.indexOf(value) == -1) {
                arr.push(value);
            }
        }

        private function pushRangeUnique(arr:Array, min:Number, max:Number):void {
            for each (var r:Object in arr) {
                if (r && r.min == min && r.max == max) {
                    return;
                }
            }
            arr.push({min:min, max:max});
        }
    }
}
