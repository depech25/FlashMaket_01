package {
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.Dictionary;
	import flash.utils.ByteArray;

	public class CRMData {
		private static var crm:Object;
		private static var initialized:Boolean = false;

		private static function loadCRMData():void {
			var file:File = File.applicationStorageDirectory.resolvePath("crm_data.json");
			var stream:FileStream = new FileStream();
			trace("App Storage Directory:", File.applicationStorageDirectory.nativePath);


			try {
				if (file.exists) {
					stream.open(file, FileMode.READ);
					var jsonString:String = stream.readUTFBytes(stream.bytesAvailable);
					crm = JSON.parse(jsonString);
					trace("[CRMData] Загружены данные CRM из JSON:", jsonString);
				} else {
					trace("[CRMData] Файл crm_data.json не найден по пути:", file.nativePath);
					crm = {};
				}
			} catch (error:Error) {
				trace("[CRMData] Ошибка при чтении JSON:", error.message);
				crm = {};
			} finally {
				stream.close();
			}
			initialized = true;
		}
		public static function getAllData():Object {
			if (!initialized) loadCRMData();
			return crm;
		}
		public static function reload():void {
			initialized = false;
			loadCRMData();
		}

		public static function getDataById(apartmentId:String, field:String):* {
			if (!initialized) loadCRMData(); // 💡 загрузка при первом обращении

			if (crm && crm.hasOwnProperty(apartmentId)) {
				var apartment:Object = crm[apartmentId];
				if (apartment.hasOwnProperty(field)) {
					return apartment[field];
				}
			}
			return null;
		}
	}
}

