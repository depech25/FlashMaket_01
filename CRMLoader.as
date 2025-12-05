package {
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.IOErrorEvent;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.net.URLRequestHeader;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;

    public class CRMLoader extends EventDispatcher {
        public static const DATA_UPDATED:String = "crmDataUpdated";

        private const API_KEY:String = "1212a891-b842-4d09-afe8-2aeb71761c73";
        private const API_LAYOUTS_URL:String = "https://data.crm-point.ru/layout";

        private var existingData:Object = {};
        private var crmLayouts:Array = [];
        private var resultData:Object = {};

        public function CRMLoader() {
            super();
        }

        public function start():void {
            loadLocalJSON();
            loadLayouts();
        }

        private function loadLocalJSON():void {
            try {
                var file:File = File.applicationStorageDirectory.resolvePath("crm_data.json");
                if (!file.exists) {
                    trace("[CRMLoader] Локальный crm_data.json не найден! Будет использоваться пустой объект.");
                    existingData = {};
                    return;
                }

                var stream:FileStream = new FileStream();
                stream.open(file, FileMode.READ);
                var raw:String = stream.readUTFBytes(stream.bytesAvailable);
                stream.close();

                existingData = JSON.parse(raw);
                trace("[CRMLoader] Загружен локальный JSON, строк: " + ObjectKeys(existingData).length);

            } catch (e:Error) {
                trace("[CRMLoader] Ошибка чтения локального JSON: " + e.message);
                existingData = {};
            }
        }

        private function loadLayouts():void {
            var req:URLRequest = new URLRequest(API_LAYOUTS_URL);
            req.requestHeaders.push(new URLRequestHeader("Authorization", API_KEY));

            var loader:URLLoader = new URLLoader();
            loader.addEventListener(Event.COMPLETE, onLayoutsLoaded);
            loader.addEventListener(IOErrorEvent.IO_ERROR, onError);
            loader.load(req);
        }

        private function onLayoutsLoaded(e:Event):void {
            try {
                crmLayouts = JSON.parse(URLLoader(e.target).data) as Array;
                trace("[CRMLoader] Загружено объектов CRM: " + crmLayouts.length);
                mergeCRM();
            } catch (err:Error) {
                trace("[CRMLoader] Ошибка парсинга CRM: " + err.message);
            }
        }

        private function mergeCRM():void {
            for (var k:String in existingData) {
                resultData[k] = existingData[k];
            }

            var statusMap:Object = {
                "свободно": "Available",
                "бронь": "Reserved",
                "куплено": "Occupied",
                "закрыт к продаже": "Сlosed for sale",
                "available": "Available",
                "reserved": "Reserved",
                "occupied": "Occupied",
                "сlosed for sale": "Сlosed for sale"
            };

            for each (var apt:Object in crmLayouts) {
                if (!apt.hasOwnProperty("number")) {
                    trace("[CRMLoader] В CRM-объекте нет поля number — пропускаем элемент.");
                    continue;
                }

                var num:String = String(apt.number);

                if (!resultData.hasOwnProperty(num)) {
                    trace("[CRMLoader] Пропуск квартиры " + num + " — её нет в локальном JSON");
                    continue;
                }

                var old:Object = resultData[num];
                var updated:Object = {};

                for (var f:String in old) {
                    updated[f] = old[f];
                }

                if (apt.hasOwnProperty("status") && apt.status != null && String(apt.status) != "") {
                    var sKey:String = String(apt.status).toLowerCase();
                    if (statusMap.hasOwnProperty(sKey)) {
                        updated.status = statusMap[sKey];
                    } else {
                        updated.status = String(apt.status);
                    }
                }

                if (apt.hasOwnProperty("area") && apt.area !== null && apt.area !== undefined) {
                    updated.square = apt.area;
                }

                if (apt.hasOwnProperty("type") && apt.type != null && String(apt.type) != "") {
                    updated.type = apt.type;
                }

                if (apt.hasOwnProperty("plan_image") && apt.plan_image != null && String(apt.plan_image) != "") {
                    updated.plan = apt.plan_image;
                }

                if (apt.hasOwnProperty("preview") && apt.preview != null && String(apt.preview) != "") {
                    updated.base_image = apt.preview;
                }

                if (apt.hasOwnProperty("images") && apt.images != null && apt.images is Array && (apt.images as Array).length > 0) {
                    updated.render = apt.images;
                }

                resultData[num] = updated;

                trace("[CRMLoader] Обновлена квартира " + num);
            }

            trace("[CRMLoader] Обновление завершено. Сохраняю файл...");
            saveData();
        }

        private function saveData():void {
            try {
                var file:File = File.applicationStorageDirectory.resolvePath("crm_data.json");
                var stream:FileStream = new FileStream();
                stream.open(file, FileMode.WRITE);
                stream.writeUTFBytes(JSON.stringify(resultData));
                stream.close();

                trace("[CRMLoader] crm_data.json успешно обновлён!");

                // Сигналим слушателям о завершении обновления данных
                dispatchEvent(new Event(DATA_UPDATED));

            } catch (e:Error) {
                trace("[CRMLoader] Ошибка записи: " + e.message);
            }
        }

        private function onError(e:IOErrorEvent):void {
            trace("[CRMLoader] Ошибка загрузки: " + e.text);
        }

        private function ObjectKeys(obj:Object):Array {
            var arr:Array = [];
            for (var k:String in obj) arr.push(k);
            return arr;
        }
    }
}
