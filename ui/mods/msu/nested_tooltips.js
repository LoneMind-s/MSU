MSU.NestedTooltip = {
	__regexp : /(?:\[|&#91;)tooltip=([\w\.]+?)\.([\w\.]+)(?:\]|&#93;)(.*?)(?:\[|&#91;)\/tooltip(?:\]|&#93;)/gm,
	__tooltipStack : [],
	__tooltipHideDelay : 200,
	__tooltipShowDelay : 200,
	TileTooltipDiv : {
		container : $("<div class='msu-tile-div'/>").appendTo($(document.body)),
		expand : function(_newPosition)
		{
			this.container.show();
			this.container.offset(_newPosition);
		},
		shrink : function()
		{
			// this.container.css({width: "0", height: "0"})
			this.container.hide();
			this.container.trigger('mouseleave.msu-tooltip-showing');
		}
	},
	KeyImgMap : {},
	bindToElement : function (_element, _tooltipParams)
	{
		_element.on('mouseenter.msu-tooltip-source', this.getBindFunction(_tooltipParams));
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
	getBindFunction : function (_tooltipParams)
	{
		return function (_event)
		{
			var self = MSU.NestedTooltip;
			var tooltipSource = $(this);
			if (tooltipSource.data('msu-nested') !== undefined) return;
			var createTooltipTimeout = setTimeout(function(){
				self.onShowTooltipTimerExpired(tooltipSource, _tooltipParams);
			}, self.__tooltipShowDelay);

			tooltipSource.on('mouseleave.msu-tooltip-loading', function (_event)
			{
				clearTimeout(createTooltipTimeout);
				tooltipSource.off('mouseleave.msu-tooltip-loading');
			})

		}
	},
	onShowTooltipTimerExpired : function(_sourceContainer, _tooltipParams)
	{
		var self = this;
		_sourceContainer.off('.msu-tooltip-loading');
		// ghetto clone to get new ref
		_tooltipParams = JSON.parse(JSON.stringify(_tooltipParams));
		// If we already have tooltips in the stack, we want to fetch the one from the first tooltip that will have received the entityId from the vanilla function
		if (this.__tooltipStack.length > 0)
			_tooltipParams.entityId = this.__tooltipStack[0].tooltip.entityId;
		Screens.TooltipScreen.mTooltipModule.notifyBackendQueryTooltipData(_tooltipParams, function (_backendData)
		{
			if (_backendData === undefined || _backendData === null)
		    {
		    	self.TileTooltipDiv.shrink();
		        return;
		    }

		    // vanilla behavior, when sth moved into tile while the data was being fetched
		    if (_tooltipParams.contentType === 'tile' || _tooltipParams.contentType === 'tile-entity')
		    	Screens.TooltipScreen.mTooltipModule.updateContentType(_backendData)

			self.createTooltip(_backendData, _sourceContainer, _tooltipParams);
		});
	},
	updateStack : function ()
	{
		for (var i = this.__tooltipStack.length - 1; i >= 0; i--)
		{
			var pairData = this.__tooltipStack[i];
			if ((pairData.source.isHovered && pairData.source.container.is(":visible")) || (pairData.tooltip.isHovered && pairData.tooltip.container.is(":visible")))
				return false;
			this.removeTooltip(pairData, i);
		}
		return true;
	},
	removeTooltip : function (_pairData, _idx)
	{
		this.cleanSourceContainer(_pairData.source.container);
		if (_pairData.tooltip.updateStackTimeout !== null)
			clearTimeout(_pairData.tooltip.updateStackTimeout);
		_pairData.tooltip.container.remove();
		this.__tooltipStack.splice(_idx, 1);
	},
	cleanSourceContainer : function(_sourceContainer)
	{
		_sourceContainer.off('.msu-tooltip-showing');
		var data = _sourceContainer.data("msu-nested");
		if (data === undefined)
			return;
		if (data.updateStackTimeout !== null)
			clearTimeout(data.updateStackTimeout);
		_sourceContainer.removeData('msu-nested');
	},
	createTooltip : function (_backendData, _sourceContainer, _tooltipParams)
	{
		var self = this;
		var tooltipContainer = this.getTooltipFromData(_backendData, _tooltipParams.contentType);
		var sourceData = {
			container : _sourceContainer,
			updateStackTimeout : null,
			isHovered : true,
			tooltipContainer : tooltipContainer
		};
		_sourceContainer.data('msu-nested', sourceData);
		var tooltipData = {
			container : tooltipContainer,
			updateStackTimeout : null,
			opacityTimeout : null,
			isHovered : false,
			isLocked : false,
			sourceContainer : _sourceContainer,
			entityId : _tooltipParams.entityId || null
		};

		tooltipContainer.data('msu-nested', tooltipData);
		this.__tooltipStack.push({
			source : sourceData,
			tooltip : tooltipData
		});
		tooltipContainer.on('mouseenter.msu-tooltip-container', function (_event)
		{
			if (!tooltipData.isLocked)
			{
				$(this).hide();
				self.cleanSourceContainer(_sourceContainer);
				return;
			}
			$(this).removeClass("msu-nested-tooltip-not-hovered");
			tooltipData.isHovered = true;
			if (tooltipData.updateStackTimeout !== null)
			{
				clearTimeout(tooltipData.updateStackTimeout);
				tooltipData.updateStackTimeout = null;
			}
			if( tooltipData.opacityTimeout !== null)
			{
				clearTimeout(tooltipData.opacityTimeout);
				tooltipData.opacityTimeout = null;
			}
		});
		tooltipContainer.on('mouseleave.msu-tooltip-container', function (_event)
		{
			tooltipData.isHovered = false;
			tooltipData.opacityTimeout = setTimeout(function(){
				$(tooltipContainer).addClass("msu-nested-tooltip-not-hovered");
			}, self.__tooltipHideDelay);
			tooltipData.updateStackTimeout = setTimeout(self.updateStack.bind(self), self.__tooltipHideDelay);
		});
		this.addTooltipLockHandler(tooltipContainer, _sourceContainer);

		this.addSourceContainerMouseHandler(_sourceContainer);

		this.addTooltipContainerMouseHandler(tooltipContainer, _sourceContainer);

		$('body').append(tooltipContainer)
		this.positionTooltip(tooltipContainer, _backendData, _sourceContainer);
	},
	addTooltipLockHandler : function(_tooltipContainer, _sourceContainer)
	{
		var nestedItems = _tooltipContainer.find(".msu-nested-tooltip");
		if (nestedItems.length == 0)
			return;
		var self = this;

		_tooltipContainer.addClass("msu-nested-tooltips-within");
		var progressImage = $("<div class='tooltip-progress-bar'/>")
			.appendTo(_tooltipContainer)

		progressImage.velocity({ opacity: 0 },
		{
	        duration: 1000,
			begin: function()
			{
				progressImage.css("opacity", 1)
	        },
			complete: function()
			{
				progressImage.remove();
				var data = _tooltipContainer.data('msu-nested');
				if (data === undefined)
				{
					return;
				}
				data.isLocked = true;
				_tooltipContainer.addClass("msu-nested-tooltips-locked");
				setTimeout(function()
				{
					_tooltipContainer.removeClass("msu-nested-tooltips-locked");
				}, 100)
	        }
	   });

		_sourceContainer.mousedown(function(){
			if (MSU.Keybinds.isMousebindPressed(MSU.ID, "LockTooltip"))
			{
				progressImage.velocity("finish");
			}

		})
	},
	addSourceContainerMouseHandler : function(_sourceContainer)
	{
		var self = this;
		_sourceContainer.on('mouseenter.msu-tooltip-showing', function(_event)
		{
			var data = $(this).data('msu-nested');
			data.isHovered = true;
			if (data.updateStackTimeout !== null)
			{
				clearTimeout(data.updateStackTimeout);
				data.updateStackTimeout = null;
			}
		});
		_sourceContainer.on('mouseleave.msu-tooltip-showing remove.msu-tooltip-showing', function (_event)
		{
			var data = $(this).data('msu-nested');
			if (data === undefined) // not sure when this comes up, but sometimes it does, and the game errors unless we do this
			{
				self.updateStack();
				return;
			}
			data.isHovered = false;
			data.updateStackTimeout = setTimeout(self.updateStack.bind(self), self.__tooltipHideDelay);
		});
	},
	addTooltipContainerMouseHandler : function(_tooltipContainer, _sourceContainer)
	{
		var self = this;
		var tooltipData = _tooltipContainer.data("msu-nested");
		_tooltipContainer.on('mouseenter.msu-tooltip-container', function (_event)
		{
			if (!tooltipData.isLocked)
			{
				$(this).hide();
				self.cleanSourceContainer(_sourceContainer);
				return;
			}
			$(this).removeClass("msu-nested-tooltip-not-hovered");
			tooltipData.isHovered = true;
			if (tooltipData.updateStackTimeout !== null)
			{
				clearTimeout(tooltipData.updateStackTimeout);
				tooltipData.updateStackTimeout = null;
			}
			if( tooltipData.opacityTimeout !== null)
			{
				clearTimeout(tooltipData.opacityTimeout);
				tooltipData.opacityTimeout = null;
			}
		});
		_tooltipContainer.on('mouseleave.msu-tooltip-container', function (_event)
		{
			tooltipData.isHovered = false;
			tooltipData.opacityTimeout = setTimeout(function(){
				_tooltipContainer.addClass("msu-nested-tooltip-not-hovered");
			}, self.__tooltipHideDelay);
			tooltipData.updateStackTimeout = setTimeout(self.updateStack.bind(self), self.__tooltipHideDelay);
		});
	},
	getTooltipFromData : function (_backendData, _contentType)
	{
		var tempContainer = Screens.TooltipScreen.mTooltipModule.mContainer;
		var ret = $('<div class="tooltip-module ui-control-tooltip-module"/>');
		Screens.TooltipScreen.mTooltipModule.mContainer = ret;
		Screens.TooltipScreen.mTooltipModule.buildFromData(_backendData, false, _contentType);
		this.parseImgPaths(ret);
		Screens.TooltipScreen.mTooltipModule.mContainer = tempContainer;
		return ret;
	},
	positionTooltip : function (_tooltip, _backendData, _targetDIV)
	{
		var tempContainer = Screens.TooltipScreen.mTooltipModule.mContainer;
		Screens.TooltipScreen.mTooltipModule.mContainer = _tooltip;
		Screens.TooltipScreen.mTooltipModule.setupUITooltip(_targetDIV, _backendData);
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

TooltipModule.prototype.showTileTooltip = function()
{
	// increase range so it's less jittery
	this.mMinMouseMovement = 20;
	if (this.mCurrentData === undefined || this.mCurrentData === null)
	{
		return;
	}
	MSU.NestedTooltip.TileTooltipDiv.expand({top: this.mLastMouseY - 30, left:this.mLastMouseX - 30});
	if (MSU.NestedTooltip.updateStack())
		MSU.NestedTooltip.onShowTooltipTimerExpired(MSU.NestedTooltip.TileTooltipDiv.container, this.mCurrentData);
};

MSU.TooltipModule_hideTileTooltip = TooltipModule.prototype.hideTileTooltip;
TooltipModule.prototype.hideTileTooltip = function()
{
	MSU.NestedTooltip.TileTooltipDiv.shrink();
	MSU.TooltipModule_hideTileTooltip.call(this);
};
