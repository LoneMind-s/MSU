"use strict";

var ModSettingsScreen = function ()
{
	MSUUIScreen.call(this);
	this.mID = "ModSettingsScreen";

	this.mModPanels = {};
	this.mChangedPanels = {};
	this.mDialogContainer = null;
	this.mListContainer = null;
	this.mListScrollContainer = null;
	this.mBackgroundImage = null;
	this.mModPageScrollContainer = null;
	this.mActiveSettings = [];
	/*

	this.mModPanels = 
	[
		{
			modID = "",
			name = "",
			settings = [
				{
					id = "",
					type = "",
					name = "",
					value = 0,
					locked = false,
				}
			]
		}
	]
	*/

}

var BooleanSetting = function (_page, _setting, _parentDiv)
{
	this.layout = $('<div class="boolean-container"/>');
	_parentDiv.append(this.layout);
	this.checkbox = $('<input type="checkbox" id= "' + _setting.id + '-id" name="' + _setting.id +'-name" />');
	this.layout.append(this.checkbox);
	this.label = $('<label class="text-font-normal font-color-subtitle" for="cb-camera-adjust">' + _setting.name + '</label>');
	this.layout.append(this.label);
	this.checkbox.iCheck({
		checkboxClass: 'icheckbox_flat-orange',
		radioClass: 'iradio_flat-orange',
		increaseArea: '30%'
    });
    this.checkbox.iCheck(_setting.value === true ? 'check' : 'uncheck')

    this.checkbox.on('ifChecked ifUnchecked', null, this, function (_event) {
    	_setting.value = !_setting.value;
    });

    // Tooltip
    this.label.bindTooltip({ contentType: 'ui-element', elementId: "msu-settings." + _page.modID + "." + _setting.id });
}

BooleanSetting.prototype.unbindTooltip = function ()
{
	this.label.unbindTooltip()
}

var RangeSetting = function (_page, _setting, _parentDiv)
{
	var self = this;
	this.layout = $('<div class="range-container line"/>');
	_parentDiv.append(this.layout);

	this.title = $('<div class="title title-font-big font-bold font-color-title">' + _setting.name + '</div>');
	this.layout.append(this.title);

	this.control = $('<div class="scale-control"/>');
	this.layout.append(this.control);

	this.slider = $('<input class="scale-slider" type="range"/>');
	this.slider.attr({
		min : _setting.min,
		max : _setting.max,
		step : _setting.step
	})
	this.slider.val(_setting.value);
	this.control.append(this.slider);

	this.label = $('<div class="scale-label text-font-normal font-color-subtitle">' + _setting.value + '</div>');
	this.control.append(this.label);

	this.layout.on("change", function () 
	{
		_setting.value = parseFloat(self.slider.val());
		self.label.text('' + _setting.value);
	});

	// Tooltip
	this.control.bindTooltip({ contentType: 'ui-element', elementId: "msu-settings." + _page.modID + "." + _setting.id });
	this.title.bindTooltip({ contentType: 'ui-element', elementId: "msu-settings." + _page.modID + "." + _setting.id });
}

RangeSetting.prototype.unbindTooltip = function ()
{
	this.control.unbindTooltip();
	this.title.unbindTooltip();
}

var EnumSetting = function (_page, _setting, _parentDiv)
{
	var self = this;
	this.setting = _setting;
	this.idx = _setting.array.indexOf(_setting.value);
	if (this.idx == -1) 
	{
		console.error("EnumSetting Error");
	}

	this.layout = $('<div class="enum-container line"/>');
	_parentDiv.append(this.layout);

	this.title = $('<div class="title title-font-big font-bold font-color-title line">' + _setting.name + '</div>');
	this.layout.append(this.title);

	this.button = this.layout.createTextButton(_setting.value, function ()
	{
		self.cycle(true);
	}, 'enum-button line', 4);

	this.button.mousedown(function (event)
	{
		if (event.which === 3)
		{
			self.cycle(false);
		}
	});

	// Tooltip
	this.title.bindTooltip({ contentType: 'ui-element', elementId: "msu-settings." + _page.modID + "." + _setting.id })
	this.button.bindTooltip({ contentType: 'ui-element', elementId: "msu-settings." + _page.modID + "." + _setting.id });
}

EnumSetting.prototype.cycle = function (_forward)
{
	console.error("pre: " + this.idx)
	this.idx += _forward ? 1 : -1;
	if (this.idx == -1)
	{
		this.idx = this.setting.array.length - 1;
	}
	else if (this.idx == this.setting.array.length)
	{
		this.idx = 0;
	}
	console.error("post: " + this.idx)
	this.setting.value = this.setting.array[this.idx];
	this.button.changeButtonText(this.setting.value);
}

EnumSetting.prototype.unbindTooltip = function ()
{
	this.title.unbindTooltip();
	this.button.unbindTooltip();
}

// Inheritance in JS
ModSettingsScreen.prototype = Object.create(MSUUIScreen.prototype)
Object.defineProperty(ModSettingsScreen.prototype, 'constructor', {
	value: ModSettingsScreen,
	enumerable: false,
	writable: true });

ModSettingsScreen.prototype.onConnection = function (_handle)
{
	MSUUIScreen.prototype.onConnection.call(this, _handle);
	this.register($('.root-screen'));
}

ModSettingsScreen.prototype.createDIV = function (_parentDiv)
{
	var self = this;
	MSUUIScreen.prototype.createDIV.call(this, _parentDiv);
	var dialogLayout = $('<div class="l-dialog-container"/>');
	this.mContainer.append(dialogLayout);
	this.mDialogContainer = dialogLayout.createDialog('Mod Settings', "Select a Mod From the List", null, false, 'dialog-1024-768');

	//Background for main menu screen
	this.mBackgroundImage = this.mContainer.createImage(null, function (_image)
	{
	    _image.removeClass('display-none').addClass('display-block');
	    _image.fitImageToParent();
	}, function (_image)
	{
	    _image.fitImageToParent();
	}, 'display-none');

	//Footer Bar
	var footerButtonBar = $('<div class="l-button-bar"></div>');
	this.mDialogContainer.findDialogFooterContainer().append(footerButtonBar);

	var layout = $('<div class="l-cancel-button"/>');
	footerButtonBar.append(layout);
	layout.createTextButton("Cancel", function ()
	{
		self.notifyBackendCancelButtonPressed();
	}, '', 1);

	var layout = $('<div class="l-ok-button"/>');
	footerButtonBar.append(layout);
	layout.createTextButton("Save", function ()
	{
		self.notifyBackendSaveButtonPressed();
	}, '', 1);

	var content = this.mContainer.findDialogContentContainer();

	//Mod List Container
	var pagesListScrollContainer = $('<div class="l-list-container"/>');
	content.append(pagesListScrollContainer);
	this.mListContainer = pagesListScrollContainer.createList(2);
	this.mListScrollContainer = this.mListContainer.findListScrollContainer();

	//Mod Page Container
	var modPageContainerLayout = $('<div class="l-page-container"/>')
	content.append(modPageContainerLayout);
    this.mModPageContainer = modPageContainerLayout.createList(2);
    this.mModPageScrollContainer = this.mModPageContainer.findListScrollContainer();
}

ModSettingsScreen.prototype.destroy = function ()
{
	for (var i = 0; i < this.mActiveSettings.length; i++) {
		this.mActiveSettings[i].remove();
	}
	this.mActiveSettings = [];
	this.mModPanels = {};
	this.mChangedPanels = {};

	MSUUIScreen.prototype.destroy.call(this);
}

ModSettingsScreen.prototype.unbindTooltips = function ()
{
	for (var i = 0; i < this.mActiveSettings.length; i++) {
		this.mActiveSettings[i].unbindTooltip();
	}

	MSUUIScreen.prototype.unbindTooltips.call(this);
}

ModSettingsScreen.prototype.destroyDIV = function ()
{
	this.mDialogContainer.empty();
	this.mDialogContainer.remove();
	this.mDialogContainer = null;

	this.mBackgroundImage.remove();
	this.mBackgroundImage = null;

	MSUUIScreen.prototype.destroyDIV.call(this);
}

ModSettingsScreen.prototype.hide = function()
{
	this.mDialogContainer.findDialogSubTitle().html("Select a Mod From the List");

	this.mModPageScrollContainer.empty();
	this.mBackgroundImage.attr('src', '');
	this.mListScrollContainer.empty()

	MSUUIScreen.prototype.hide.call(this);
}

ModSettingsScreen.prototype.show = function (_data)
{
	this.mBackgroundImage.attr('src', Screens["MainMenuScreen"].mBackgroundImage.attr('src'));

	this.mModPanels = _data;
	this.createModPageList();

	MSUUIScreen.prototype.show.call(this,_data);
}

ModSettingsScreen.prototype.createModPageList = function ()
{
	for (var i = this.mModPanels.length - 1; i >= 0; i--) {
		this.addModPageButtonToList(this.mModPanels[i]);
	}
}

ModSettingsScreen.prototype.addModPageButtonToList = function (_page)
{
	var self = this;
	this.mListScrollContainer.createTextButton(_page.name, function ()
	{
		self.switchToMod(_page);
	}, 'l-button', 4);
}

ModSettingsScreen.prototype.switchToMod = function (_page)
{
	for (var i = 0; i < this.mActiveSettings.length; i++) {
		this.mActiveSettings[i].unbindTooltip();
	}
	this.mActiveSettings = [];
	this.mModPageScrollContainer.empty()

	this.mContainer.findDialogSubTitle().html(_page.name)
	for (var i = 0; i < _page.settings.length; i++)
	{
		var setting = new window[_page.settings[i].type + "Setting"](_page, _page.settings[i], this.mModPageScrollContainer)
		this.mActiveSettings.push(setting);
	}
}

ModSettingsScreen.prototype.getChanges = function ()
{
	var changes = {}
	for (var i = this.mModPanels.length - 1; i >= 0; i--) {
		var modID = this.mModPanels[i].modID;
		changes[modID] = {};
		for (var j = this.mModPanels[i].settings.length - 1; j >= 0; j--) {
			var settingID = this.mModPanels[i].settings[j].id;
			changes[modID][settingID] = this.mModPanels[i].settings[j].value;
		}
	}
	return changes;
}

ModSettingsScreen.prototype.notifyBackendCancelButtonPressed = function ()
{
	SQ.call(this.mSQHandle, 'onCancelButtonPressed');
}

ModSettingsScreen.prototype.notifyBackendSaveButtonPressed = function ()
{
	SQ.call(this.mSQHandle, 'onSaveButtonPressed', this.getChanges());
}

{ // Don't like this, should be improved
	var show = MainMenuScreen.prototype.show;
	MainMenuScreen.prototype.show = function ()
	{
		show.call(this)
		if (Screens["ModSettingsScreen"].mBackgroundImage !== null)
		{
			this.mBackgroundImage.attr('src', Screens["ModSettingsScreen"].mBackgroundImage.attr('src'));
		}
	}
}

registerScreen("ModSettingsScreen", new ModSettingsScreen());
