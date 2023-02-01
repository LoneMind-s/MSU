MSU.NestedTooltip = {
	__regexp : /(?:\[|&#91;)tooltip=([\w\.]+?)\.([\w\.]+)(?:\]|&#93;)(.*?)(?:\[|&#91;)\/tooltip(?:\]|&#93;)/gm,
	__tooltipStack : [],
	__tooltipHideDelay : 200,
	__tooltipShowDelay : 200,
	KeyImgMap : {},
	bindToElement : function (_element, _data)
	{
		_element.on('mouseenter.msu-tooltip-source', this.getBindFunction(_data));
	},
	unbindFromElement : function (_element)
	{
		var data = _element.data('msu-nested');
		if (data !== undefined)
		{
			data.isHovered = false;
			this.updateStack();
		}
		_element.off('.msu-tooltip-source');
	},
	getBindFunction : function (_data)
	{
		return function (_event)
		{
			var element = $(this);
			if (element.data('msu-nested') !== undefined) return;
			var self = MSU.NestedTooltip;
			var timeout = setTimeout(function() {
				element.off('.msu-tooltip-loading');
				self.updateStack();
				Screens.TooltipScreen.mTooltipModule.notifyBackendQueryTooltipData(_data, function (_backendData)
				{
					self.createTooltip(_backendData, element, _data.contentType);
				});
				element.on('mouseenter.msu-tooltip-showing', function(_event)
				{
					var data = $(this).data('msu-nested');
					data.isHovered = true;
					if (data.timeout !== null)
					{
						clearTimeout(data.timeout);
						data.timeout = null;
					}
				});
				element.on('mouseleave.msu-tooltip-showing remove.msu-tooltip-showing', function (_event)
				{
					var data = $(this).data('msu-nested');
					if (data === undefined) // not sure when this comes up, but sometimes it does, and the game errors unless we do this
					{
						self.updateStack();
						return;
					}
					data.isHovered = false;
					data.timeout = setTimeout(self.updateStack.bind(self), self.__tooltipHideDelay);
				});
			}, self.__tooltipShowDelay);

			element.on('mouseleave.msu-tooltip-loading', function (_event)
			{
				clearTimeout(timeout);
				element.off('mouseleave.msu-tooltip-loading');
			})

		}
	},
	updateStack : function ()
	{
		for (var i = this.__tooltipStack.length - 1; i >= 0; i--)
		{
			var pairData = this.__tooltipStack[i];
			if (pairData.source.isHovered || pairData.tooltip.isHovered)
				break;
			this.removeTooltip(pairData, i);
		}
	},
	removeTooltip : function (_pairData, _idx)
	{
		if (_pairData.source.timeout !== null)
			clearTimeout(_pairData.source.timeout);
		if (_pairData.tooltip.timeout !== null)
			clearTimeout(_pairData.tooltip.timeout);
		_pairData.source.container.off('.msu-tooltip-showing');
		_pairData.source.container.removeData('msu-nested');
		_pairData.tooltip.container.remove();
		this.__tooltipStack.splice(_idx, 1);
	},
	createTooltip : function (_data, _sourceElement, _contentType)
	{
		var container = this.getTooltipFromData(_data, _contentType);
		var self = this;
		var sourceData = {
			container : _sourceElement,
			timeout : null,
			isHovered : true
		};
		_sourceElement.data('msu-nested', sourceData);
		var tooltipData = {
			container : container,
			timeout : null,
			isHovered : false
		};
		container.data('msu-nested', tooltipData);
		this.__tooltipStack.push({
			source : sourceData,
			tooltip : tooltipData
		});
		container.on('mouseenter.msu-tooltip-tooltip', function (_event)
		{
			var data = $(this).data('msu-nested');
			data.isHovered = $(this).find(".msu-nested-tooltip").length > 0;
			if (data.timeout !== null)
			{
				clearTimeout(data.timeout);
				data.timeout = null;
			}
		});
		container.on('mouseleave.msu-tooltip-tooltip', function (_event)
		{
			var data = $(this).data('msu-nested');
			data.isHovered = false;
			data.timeout = setTimeout(self.updateStack.bind(self), self.__tooltipHideDelay);
		});

		$('body').append(container)
		this.positionTooltip(container, _data, _sourceElement);
	},
	getTooltipFromData : function (_data, _contentType)
	{
		var tempContainer = Screens.TooltipScreen.mTooltipModule.mContainer;
		var ret = $('<div class="tooltip-module ui-control-tooltip-module"/>');
		Screens.TooltipScreen.mTooltipModule.mContainer = ret;
		Screens.TooltipScreen.mTooltipModule.buildFromData(_data, false, _contentType);
		this.parseImgPaths(ret);
		Screens.TooltipScreen.mTooltipModule.mContainer = tempContainer;
		return ret;
	},
	positionTooltip : function (_tooltip, _data, _targetDIV)
	{
		var tempContainer = Screens.TooltipScreen.mTooltipModule.mContainer;
		Screens.TooltipScreen.mTooltipModule.mContainer = _tooltip;
		Screens.TooltipScreen.mTooltipModule.setupUITooltip(_targetDIV, _data);
		Screens.TooltipScreen.mTooltipModule.mContainer = tempContainer;
	},
	getTooltipLinkHTML : function (_mod, _id, _text)
	{
		_text = _text || "";
		return '<div class="msu-nested-tooltip" data-msu-nested-mod="' + _mod + '" data-msu-nested-id="' + _id + '">' + _text + '</div>';
	},
	parseText : function (_text)
	{
		var self = this;
		return _text.replace(this.__regexp, function (_match, _mod, _id, _text)
		{
			return self.getTooltipLinkHTML(_mod, _id, _text);
		})
	},
	parseImgPaths : function (_jqueryObj)
	{
		var self = this;
		_jqueryObj.find('img').each(function ()
		{
			if (this.src in self.KeyImgMap)
			{
				var entry = self.KeyImgMap[this.src];
				var img = $(this);
				var div = $(self.getTooltipLinkHTML(entry.mod, entry.id));
				img.after(div);
				div.append(img.detach());
			}
		})
	}
}
MSU.XBBCODE_process = XBBCODE.process;
// I hate this but the XBBCODE plugin doesn't allow dynamically adding tags
// there's a fork that does here https://github.com/patorjk/Extendible-BBCode-Parser
// but we'd have to tweak it a bunch to add the vanilla tags
// it also changes some other stuff and is somewhat out of date at this point
// then again, the one used in vanilla is probably even more outdated
XBBCODE.process = function (config)
{
	var ret = MSU.XBBCODE_process.call(this, config);
	ret.html = MSU.NestedTooltip.parseText(ret.html)
	return ret;
}


$.fn.bindTooltip = function (_data)
{
	MSU.NestedTooltip.bindToElement(this, _data);
};

$.fn.unbindTooltip = function ()
{
	MSU.NestedTooltip.unbindFromElement(this);
};

$(document).on('mouseenter.msu-tooltip-source', '.msu-nested-tooltip', function()
{
	var data = {
		contentType : 'msu-nested-tooltip',
		elementId : this.dataset.msuNestedId,
		modId : this.dataset.msuNestedMod
	}
	MSU.NestedTooltip.getBindFunction(data).call(this);
})
