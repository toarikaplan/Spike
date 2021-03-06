package ui.screens.display.settings.transmitter
{
	import database.BlueToothDevice;
	import database.CommonSettings;
	
	import feathers.controls.Alert;
	import feathers.controls.Button;
	import feathers.controls.List;
	import feathers.controls.PickerList;
	import feathers.controls.TextInput;
	import feathers.controls.popups.DropDownPopUpContentManager;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.events.FeathersEventType;
	import feathers.layout.HorizontalAlign;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	import starling.text.TextFormat;
	
	import ui.AppInterface;
	import ui.popups.AlertManager;
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	[ResourceBundle("transmittersettingsscreen")]
	[ResourceBundle("transmitterscreen")]
	[ResourceBundle("globaltranslations")]

	public class TransmitterSettingsList extends List 
	{
		/* Display Objects */
		private var transmitterID:TextInput;
		private var transmitterType:PickerList;
		
		/* Properties */
		public var needsSave:Boolean = false;
		public var warnUser:Boolean = false;
		private var transmitterTypeValue:String;
		private var transmitterIDValue:String;
		private var currentTransmitterIndex:int;
		private var transmitterIDisEnabled:Boolean;
		
		public function TransmitterSettingsList()
		{
			super();
		}
		override protected function initialize():void 
		{
			super.initialize();
			
			setupProperties();
			setupInitialState();
			setupContent();
			
			addEventListener(FeathersEventType.CREATION_COMPLETE, onCreation);
		}
		
		/**
		 * Functionality
		 */
		private function setupProperties():void
		{
			//Set Properties
			clipContent = false;
			isSelectable = false;
			autoHideBackground = true;
			hasElasticEdges = false;
			paddingBottom = 5;
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
		}
		
		private function setupInitialState():void
		{
			/* Get Values From Database */
			transmitterIDValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID);
			if (!BlueToothDevice.needsTransmitterId())
				transmitterIDValue = "";
			transmitterTypeValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE);
			trace("transmitterTypeValue", transmitterTypeValue);
			
			/* Ensure BluCon and Dexcom compatibility */
			if (transmitterTypeValue == "BluKon")
				transmitterTypeValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_blucon');
			else if (transmitterTypeValue == "G5")
				transmitterTypeValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_dexcom_g5');
			else if (transmitterTypeValue == "G4")
				transmitterTypeValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_dexcom_g4');
			else if (!BlueToothDevice.needsTransmitterId() || transmitterTypeValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_limitter') || transmitterTypeValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_bluereader') || transmitterTypeValue.toUpperCase() == "TRANSMITER PL")
				transmitterIDisEnabled = false;
		}
		
		private function setupContent():void
		{
			//Transmitter Type Picker List
			transmitterType = LayoutFactory.createPickerList();
			var transitterNamesList:Array = ModelLocator.resourceManagerInstance.getString('transmittersettingsscreen','transmitter_type_list').split(",");
			var transmitterTypeList:ArrayCollection = new ArrayCollection();
			for (var i:int = 0; i < transitterNamesList.length; i++) 
			{
				transmitterTypeList.push({label: transitterNamesList[i], id: i});
				if(transitterNamesList[i] == transmitterTypeValue)
					currentTransmitterIndex = i;
			}
			transitterNamesList.length = 0;
			transitterNamesList = null;
			transmitterType.labelField = "label";
			transmitterType.popUpContentManager = new DropDownPopUpContentManager();
			transmitterType.dataProvider = transmitterTypeList;
			if(DeviceInfo.getDeviceType() == DeviceInfo.IPHONE_X)
			{
				transmitterType.buttonFactory = function():Button
				{
					var button:Button = new Button();
					button.fontStyles = new TextFormat("Roboto", 10, 0xEEEEEE);
					return button;
				};
			}
			transmitterType.itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				itemRenderer.paddingRight = 6;
				itemRenderer.paddingLeft = 6;
				return itemRenderer;
			}
			
			if(transmitterTypeValue == "" || transmitterTypeValue == "Follow")
			{
				transmitterType.prompt = ModelLocator.resourceManagerInstance.getString('globaltranslations','picker_select');
				transmitterType.selectedIndex = -1;
			}
			else transmitterType.selectedIndex = currentTransmitterIndex;
			
			transmitterType.addEventListener(Event.CHANGE, onTransmitterTypeChange);
			
			//Transmitter ID
			transmitterID = LayoutFactory.createTextInput(false, false, 100, HorizontalAlign.RIGHT);
			transmitterID.text = transmitterIDValue;
			populateTransmitterIDPrompt();
			transmitterID.addEventListener( FeathersEventType.ENTER, onTextInputEnter );
			transmitterID.addEventListener(Event.CHANGE, onTransmitterIDChange);
			transmitterID.addEventListener( FeathersEventType.FOCUS_OUT, onValidateTransmitterID );
			
			//Set Item Renderer
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				itemRenderer.accessoryField = "accessory";
				itemRenderer.paddingRight = 0;
				
				return itemRenderer;
			};
			
			//Set Data Provider
			dataProvider = new ArrayCollection(
				[
					{ label: ModelLocator.resourceManagerInstance.getString('transmittersettingsscreen','transmitter_type_settings_title'), accessory: transmitterType },
					{ label: ModelLocator.resourceManagerInstance.getString('transmittersettingsscreen','transmitter_id_settings_title'), accessory: transmitterID },
				]);
			
			checkWarn();
		}
		
		private function populateTransmitterIDPrompt():void
		{
			if (transmitterTypeValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_dexcom_g5') && transmitterID.text == "")
			{
				transmitterIDisEnabled = transmitterID.isEnabled = true;
				transmitterID.prompt = "XXXXXX";
			}
			else if (transmitterTypeValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_dexcom_g4') && transmitterID.text == "")
			{
				transmitterIDisEnabled = transmitterID.isEnabled = true;
				transmitterID.prompt = "XXXXX";
			}
			else if (transmitterTypeValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_bluereader') && transmitterID.text == "")
			{
				transmitterIDisEnabled = transmitterID.isEnabled = false;
				transmitterID.prompt = "";
			}
			else if (transmitterTypeValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_blucon') && transmitterID.text == "")
			{
				transmitterIDisEnabled = transmitterID.isEnabled = true;
				transmitterID.prompt = "BLUXXXXX";
			}
			else if ((!BlueToothDevice.needsTransmitterId() || transmitterTypeValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_limitter') || transmitterTypeValue.toUpperCase() == "TRANSMITER PL") && transmitterID.text == "")
			{
				transmitterIDisEnabled = transmitterID.isEnabled = false;
				transmitterID.prompt = "";
			}
		}
		
		public function save():void
		{
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID) != transmitterIDValue.toUpperCase())
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID, transmitterIDValue.toUpperCase());
			
			/* Save BluCon as BluKon in database to ensure compatibility, correct Dexcom G5 and G4 values */
			var transmitterTypeToSave:String = transmitterTypeValue;
			if (transmitterTypeToSave == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_blucon'))
				transmitterTypeToSave = "BluKon";
			else if (transmitterTypeToSave == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_dexcom_g5'))
				transmitterTypeToSave = "G5";
			else if (transmitterTypeToSave == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_dexcom_g4'))
				transmitterTypeToSave = "G4";
			
			if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE) != transmitterTypeToSave)
			{
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE, transmitterTypeToSave);
				updateAlarms(); //Update battery values in existing alarms or delete them in case it's not possible to get alarms for the selected transmitter type
			}
			
			//Reset all transmitters battery levels
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_G5_VOLTAGEA, "unknown");
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_G5_VOLTAGEB, "unknown");
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_G5_RESIST, "unknown");
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_G5_TEMPERATURE, "unknown");
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_G5_RUNTIME, "unknown");
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_G5_STATUS, "unknown");
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_G5_BATTERY_FROM_MARKER, "0");
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_G4_TRANSMITTER_BATTERY_VOLTAGE, "0");
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_FSL_SENSOR_BATTERY_LEVEL, "0");
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_BLUEREADER_BATTERY_LEVEL, "0");
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_BLUKON_BATTERY_LEVEL, "0");
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_FSL_SENSOR_AGE, "0");
			
			//Set collection mode to host
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_MODE, "Host");
			
			//Refresh main menu. Menu items are different for hosts and followers
			AppInterface.instance.menu.refreshContent();
			
			needsSave = false;
		}
		
		private function updateAlarms():void
		{
			/* Get database alarm settings */
			var alarmCompleteSettings:String = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BATTERY_ALERT);
			
			/* Process alarm into an Array */
			var alarmsData:Array = alarmCompleteSettings.split("-");
			var alarmsSettings:Array = [];
			var numAlarms:int = alarmsData.length;
			var i:int
			for (i = 0; i < numAlarms; i++) 
			{
				var alarmSetting:Array = (alarmsData[i] as String).split(">");
				
				var alarm:Object = {};
				alarm.startTime = alarmSetting[0];
				alarm.value = alarmSetting[1];
				alarm.alertType = alarmSetting[2];
				
				alarmsSettings.push(alarm);
			}
			
			/* Update Alarms */
			//Define attery value
			var batteryValue:String;
			if (transmitterTypeValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_dexcom_g5'))
				batteryValue = "300";
			else if (transmitterTypeValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_dexcom_g4'))
				batteryValue = "210";
			else if (transmitterTypeValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_blucon'))
				batteryValue = "5";
			
			//Process Alarms
			if (transmitterTypeValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_bluereader') || transmitterTypeValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_limitter'))
			{
				//Clear all alarms and set it to a single NO ALERT filler
				alarmsSettings.length = 0;
				alarmsSettings.push( { startTime: "00:00", value: "0", alertType: "No Alert" } );
			}
			else
			{
				//Update battery values
				numAlarms = alarmsSettings.length;
				for (i = 0; i < numAlarms; i++) 
				{
					(alarmsSettings[i] as Object).value = batteryValue;
				}
			}
			
			/* Create Settings */
			var finalAlarmSettings:String = "";
			numAlarms = alarmsSettings.length;
			for (i = 0; i < numAlarms; i++) 
			{
				var alarmObject:Object = alarmsSettings[i];
				finalAlarmSettings += alarmObject.startTime;
				finalAlarmSettings += ">";
				finalAlarmSettings += alarmObject.value;
				finalAlarmSettings += ">";
				finalAlarmSettings += alarmObject.alertType;
				if (i < numAlarms - 1)
					finalAlarmSettings += "-";
			}
			
			/* Save settings to database */
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_BATTERY_ALERT, finalAlarmSettings);
		}
		
		private function checkWarn():void
		{
			if ((transmitterTypeValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_dexcom_g5') ||
				transmitterTypeValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_dexcom_g4') ||
				transmitterTypeValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_blucon')) &&
				transmitterID.text == "")
			{
				warnUser = true;
			}
			else
				warnUser = false;
			}
		
		/**
		 * Event Handlers
		 */
		private function onTransmitterTypeChange(e:Event):void
		{	
			transmitterTypeValue = transmitterType.selectedItem.label;
			
			if (transmitterTypeValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_limitter'))
			{
				AlertManager.showSimpleAlert(
					ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
					ModelLocator.resourceManagerInstance.getString('transmittersettingsscreen','limitter_warning_message')
				);
			}
			else if (transmitterTypeValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_blucon'))
			{
				var alert:Alert = AlertManager.showSimpleAlert(
					ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_blucon'),
					ModelLocator.resourceManagerInstance.getString('transmittersettingsscreen','blucon_id_initial_warning_message')
				);
				alert.height = 310;
			}
			
			transmitterIDValue = "";
			transmitterID.text = transmitterIDValue;
			
			populateTransmitterIDPrompt();
			
			checkWarn();
			
			needsSave = true;
		}
		
		private function onTransmitterIDChange(e:Event):void
		{
			transmitterIDValue = transmitterID.text;
			
			checkWarn();
			
			needsSave = true;
		}
		
		private function onValidateTransmitterID():void
		{
			var warningTitle:String;
			var warningMessage:String
			
			/* Validate BluCon ID */
			if (transmitterTypeValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_blucon'))
			{
				warningTitle = ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_blucon');
				
				if (transmitterID.text.length != 8) //Incorrect number of characters
					warningMessage = ModelLocator.resourceManagerInstance.getString('transmittersettingsscreen','blucon_id_wrong_number_characters_message');
				else if (transmitterID.text.slice(0, 3) != "BLU") //Missing BLU prefix
					warningMessage = ModelLocator.resourceManagerInstance.getString('transmittersettingsscreen','blucon_id_missing_blu_message');
				else if(isNaN(Number(transmitterID.text.slice(3, transmitterID.text.length)))) //Last 5 characters are not digits
						warningMessage = ModelLocator.resourceManagerInstance.getString('transmittersettingsscreen','blucon_id_wrong_last_5_characters_message');
			}
			/* Validate Dexcom G5 ID */
			else if (transmitterTypeValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_dexcom_g5') && transmitterID.text.length != 6) //Incorrect number of characters
			{
				warningTitle = ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_dexcom_g5');
				warningMessage = ModelLocator.resourceManagerInstance.getString('transmittersettingsscreen','dexcom_g5_id_wrong_number_characters_message');
			}	
			/* Validate Dexcom G4 ID */
			else if (transmitterTypeValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_dexcom_g4') && transmitterID.text.length != 5) //Incorrect number of characters
			{
				warningTitle = ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_dexcom_g4');
				warningMessage = ModelLocator.resourceManagerInstance.getString('transmittersettingsscreen','dexcom_g4_id_wrong__number_characters_message');
			}
			
			/* Show Alert */
			if(warningMessage != null)
				AlertManager.showSimpleAlert
				(
					warningTitle,
					warningMessage
				);
		}
		
		private function onTextInputEnter(event:Event):void
		{
			//Clear focus to dismiss the keyboard
			transmitterID.clearFocus();
		}
		
		private function onCreation():void
		{
			populateTransmitterIDPrompt();
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			removeEventListener(FeathersEventType.CREATION_COMPLETE, onCreation);
			
			if(transmitterID != null)
			{
				transmitterID.removeEventListener( FeathersEventType.ENTER, onTextInputEnter );
				transmitterID.removeEventListener(Event.CHANGE, onTransmitterIDChange);
				transmitterID.removeEventListener( FeathersEventType.FOCUS_OUT, onValidateTransmitterID );
				transmitterID.dispose();
				transmitterID = null;
			}
			if(transmitterType != null)
			{
				transmitterType.removeEventListener(Event.CHANGE, onTransmitterTypeChange);
				transmitterType.dispose();
				transmitterType = null;
			}
			
			super.dispose();
		}
	}
}