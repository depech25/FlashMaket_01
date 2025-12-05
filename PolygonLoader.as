package  
{
    import flash.display.Sprite;
    import flash.display.DisplayObjectContainer;
    import flash.events.Event;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.utils.getQualifiedClassName;
    import flash.events.IOErrorEvent;
	
    public class PolygonLoader extends Sprite
    {
        private var jsonPath:String;
        private var stageW:Number;
        private var stageH:Number;
        private var scale:Number;
        private var offsetX:Number;
        private var offsetY:Number;

        private var targetContainer:DisplayObjectContainer;  // <-- сюда добавляем кнопки

        public function PolygonLoader(jsonPath:String, stageW:Number, stageH:Number, targetContainer:DisplayObjectContainer, scale:Number = 1, offsetX:Number = 0, offsetY:Number = 0)
        {
            this.jsonPath = jsonPath;
            this.stageW = stageW;
            this.stageH = stageH;
            this.scale = scale;
            this.offsetX = offsetX;
            this.offsetY = offsetY;

            this.targetContainer = targetContainer;

            this.addEventListener(Event.REMOVED_FROM_STAGE, onRemoved);

            loadJson();
        }

        private function loadJson():void
        {
            var loader:URLLoader = new URLLoader();
            loader.addEventListener(Event.COMPLETE, onJsonLoaded);
            loader.addEventListener(IOErrorEvent.IO_ERROR, onJsonError);
            loader.load(new URLRequest(jsonPath));
        }

        private function onRemoved(e:Event):void
        {
            // Удаляем всех детей (кнопки)
            if (targetContainer) {
                while (targetContainer.numChildren > 0)
                {
                    targetContainer.removeChildAt(0);
                }
            } else {
                while (numChildren > 0)
                {
                    removeChildAt(0);
                }
            }

            this.removeEventListener(Event.REMOVED_FROM_STAGE, onRemoved);
        }

        private function onJsonError(e:IOErrorEvent):void
        {
            trace("[PolygonLoader] Ошибка загрузки JSON:", e.text);
        }

        private function onJsonLoaded(e:Event):void
        {
            var raw:String = e.target.data;
            var data:Object;

            try {
                data = JSON.parse(raw);
            } catch (err:Error) {
                trace("[PolygonLoader] Некорректный JSON:", err.message);
                return;
            }

            if (!(data is Array)) {
                trace("[PolygonLoader] Ошибка: JSON должен быть массивом объектов [{name:'', points:[]}, ...]");
                trace("[PolygonLoader] Вместо этого получено:", getQualifiedClassName(data));
                return;
            }

            trace("[PolygonLoader] Загружено полигонов:", data.length);

            createButtons(data as Array);
        }

        private function createButtons(polygons:Array):void
        {
            var minX:Number = Number.MAX_VALUE;
            var maxX:Number = Number.MIN_VALUE;
            var minY:Number = Number.MAX_VALUE;
            var maxY:Number = Number.MIN_VALUE;

            for each (var poly:Object in polygons)
            {
                if (!poly.name || !poly.points) continue;

                for each (var pt:Array in poly.points)
                {
                    if (pt.length != 2) continue;

                    var px:Number = pt[0];
                    var py:Number = pt[1];

                    if (px < minX) minX = px;
                    if (px > maxX) maxX = px;
                    if (py < minY) minY = py;
                    if (py > maxY) maxY = py;
                }
            }

            var dataWidth:Number = maxX - minX;
            var dataHeight:Number = maxY - minY;

            var targetWidth:Number = 1920;
            var targetHeight:Number = 1080;

            var scaleX:Number = targetWidth / dataWidth * scale;
            var scaleY:Number = targetHeight / dataHeight * scale;
            var usedScale:Number = Math.min(scaleX, scaleY);

            var scaledWidth:Number = dataWidth * usedScale;
            var scaledHeight:Number = dataHeight * usedScale;

            var sceneCenterX:Number = targetWidth / 2;
            var sceneCenterY:Number = targetHeight / 2;

            var dataCenterX:Number = scaledWidth / 2;
            var dataCenterY:Number = scaledHeight / 2;

            var finalOffsetX:Number = sceneCenterX - dataCenterX + offsetX;
            var finalOffsetY:Number = sceneCenterY - dataCenterY + offsetY;

            // Инициализируем глобальный массив, очищаем если уже есть
            if (!GlobalData.apartmentButtons) {
                GlobalData.apartmentButtons = [];
            } else {
                GlobalData.apartmentButtons.length = 0;
            }

            for each (poly in polygons)
            {
                if (!poly.name || !poly.points) {
                    trace("[PolygonLoader] Пропуск объекта — нужен {name:'', points:[...]}");
                    continue;
                }

                var ab:ApartmentButtonNew = new ApartmentButtonNew();
                ab.apartmentNumber = poly.name;
                ab.setColorByStatus(); // вызов установки цвета по статусу

                var pixelPoints:Array = [];

                for each (pt in poly.points)
                {
                    if (pt.length != 2) continue;

                    var normX:Number = pt[0] - minX;
                    var normY:Number = pt[1] - minY;

                    var scaledX:Number = normX * usedScale;
                    var scaledY:Number = normY * usedScale;

                    var finalX:Number = scaledX + finalOffsetX;
                    var finalY:Number = targetHeight - (scaledY + finalOffsetY);

                    pixelPoints.push([finalX, finalY]);
                }

                ab.setShape(pixelPoints);

                if (targetContainer) {
                    targetContainer.addChild(ab);
                } else {
                    addChild(ab);
                }

                GlobalData.apartmentButtons.push(ab);
            }
        }

    }
}
