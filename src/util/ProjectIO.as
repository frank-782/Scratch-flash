/*
 * Scratch Project Editor and Player
 * Copyright (C) 2014 Massachusetts Institute of Technology
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

// ProjectIO.as
// John Maloney, September 2010
//
// Support for project saving/loading, either to the local file system or a server.
// Three types of projects are supported: old Scratch projects (.sb), new Scratch
// projects stored as a JSON project file and a collection of media files packed
// in a single ZIP file, and new Scratch projects stored on a server as a collection
// of separate elements.

package util {
import flash.display.*;
import flash.events.*;
import flash.net.URLLoader;
import flash.utils.*;
import by.blooddy.crypto.MD5;
//import by.blooddy.crypto.MD5;
import flash.display.BitmapData;
import flash.display.Loader;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.events.SecurityErrorEvent;
import flash.external.ExternalInterface;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequest;
import flash.utils.ByteArray;
import flash.utils.setTimeout;
import flash.utils.Dictionary;

import logging.LogLevel;

import scratch.*;
import util.jsons
import sound.WAVFile;
import sound.mp3.MP3Loader;

import svgutils.*;

import translation.Translator;

import uiwidgets.DialogBox;

public class ProjectIO {

	protected var app:Scratch;
	protected var images:Array = [];
	protected var sounds:Array = [];
	private static var serverAssets:Object = {};

	public function ProjectIO(app:Scratch):void {
		this.app = app;
	}

	private static var translationStrings:Object = {
		imageLoadingErrorTitle: 'Image Loading Error',
		imageLoadingErrorHeader: 'At least one backdrop or costume failed to load:',
		imageLoadingErrorBackdrop: 'Backdrop: {costumeName}',
		imageLoadingErrorSprite: 'Sprite: {spriteName}',
		imageLoadingErrorCostume: 'Costume: {costumeName}'
	};

	public static function strings():Array {
		var result:Array = [];
		for each (var key:String in translationStrings) {
			if (translationStrings.hasOwnProperty(key)) {
				result.push(translationStrings[key]);
			}
		}
		return result;
	}

	//----------------------------
	// Encode a project or sprite as a ByteArray (a 'one-file' project)
	//----------------------------

	public function encodeProjectAsZipFile(proj:ScratchStage):ByteArray {
		// Encode a project into a ByteArray. The format is a ZIP file containing
		// the JSON project data and all images and sounds as files.
		delete proj.info.penTrails; // remove the penTrails bitmap saved in some old projects' info
		proj.savePenLayer();
		proj.updateInfo();
		recordImagesAndSounds(proj.allObjects(), false, proj);
		var zip:ZipIO = new ZipIO();
		zip.startWrite();
		addJSONData('project.json', proj, zip);
		addImagesAndSounds(zip);
		proj.clearPenLayer();
		return zip.endWrite();
	}

	public function encodeSpriteAsZipFile(spr:ScratchSprite):ByteArray {
		// Encode a sprite into a ByteArray. The format is a ZIP file containing
		// the JSON sprite data a
		// nd all images and sounds as files.
		recordImagesAndSounds([spr], false);
		var zip:ZipIO = new ZipIO();
		zip.startWrite();
		addJSONData('sprite.json', spr, zip);
		addImagesAndSounds(zip);
		return zip.endWrite();
	}

	protected function getScratchStage():ScratchStage {
		return new ScratchStage();
	}

	private function addJSONData(fileName:String, obj:*, zip:ZipIO):void {
		var jsonData:ByteArray = new ByteArray();
		jsonData.writeUTFBytes(util.JSON.stringify(obj));
		zip.write(fileName, jsonData, true);
	}


	private function addImagesAndSounds(zip:ZipIO):void {
		var i:int, ext:String;
		for (i = 0; i < images.length; i++) {
			var imgData:ByteArray = images[i][1];
			ext = ScratchCostume.fileExtension(imgData);
			zip.write(i + ext, imgData);
		}
		for (i = 0; i < sounds.length; i++) {
			var sndData:ByteArray = sounds[i][1];
			ext = ScratchSound.isWAV(sndData) ? '.wav' : '.mp3';
			zip.write(i + ext, sndData);
		}
	}

	//----------------------------
	// Decode a project or sprite from a ByteArray containing ZIP data
	//----------------------------

	public function decodeProjectFromZipFile(zipData:ByteArray):ScratchStage {
		return decodeFromZipFile(zipData) as ScratchStage;
	}

	public function decodeSpriteFromZipFile(zipData:ByteArray, whenDone:Function, fail:Function = null):void {
		function imagesDecoded():void {
			spr.showCostume(spr.currentCostumeIndex);
			whenDone(spr);
		}
		var spr:ScratchSprite = decodeFromZipFile(zipData) as ScratchSprite;
		if (spr) decodeAllImages([spr], imagesDecoded, fail);
		else if (fail != null) fail();
	}

	protected function decodeFromZipFile(zipData:ByteArray):ScratchObj {
		var jsonData:String;
		images = [];
		sounds = [];
		try {
			var files:Array = new ZipIO().read(zipData);
		} catch (e:*) {
			app.log(LogLevel.WARNING, 'Bad zip file; attempting to recover');
			try {
				files = new ZipIO().recover(zipData);
			} catch (e:*) {
				return null; // couldn't recover
			}
		}
		for each (var f:Array in files) {
			var fName:String = f[0];
			if (fName.indexOf('__MACOSX') > -1) continue; // skip MacOS meta info in zip file
			var fIndex:int = int(integerName(fName));
			var contents:ByteArray = f[1];
			if (fName.slice(-4) == '.gif') images[fIndex] = contents;
			if (fName.slice(-4) == '.jpg') images[fIndex] = contents;
			if (fName.slice(-4) == '.png') images[fIndex] = contents;
			if (fName.slice(-4) == '.svg') images[fIndex] = contents;
			if (fName.slice(-4) == '.wav') sounds[fIndex] = contents;
			if (fName.slice(-4) == '.mp3') sounds[fIndex] = contents;
			if (fName.slice(-5) == '.json') jsonData = contents.readUTFBytes(contents.length);
		}
		if (jsonData == null) return null;
		var jsonObj:Object = jsons.parse(jsonData);
		if (jsonObj['children']) { // project JSON
			var proj:ScratchStage = getScratchStage();
			proj.readJSON(jsonObj);
			if (proj.penLayerID >= 0) proj.penLayerPNG = images[proj.penLayerID]
			else if (proj.penLayerMD5) proj.penLayerPNG = images[0];
			installImagesAndSounds(proj.allObjects());
			return proj;
		}
		if (jsonObj['direction'] != null) { // sprite JSON
			var sprite:ScratchSprite = new ScratchSprite();
			sprite.readJSON(jsonObj);
			sprite.instantiateFromJSON(app.stagePane)
			installImagesAndSounds([sprite]);
			return sprite;
		}
		return null;
	}

	private function integerName(s:String):String {
		// Return the substring of digits preceding the last '.' in the given string.
		// For example integerName('123.jpg') -> '123'.
		const digits:String = '1234567890';
		var end:int = s.lastIndexOf('.');
		if (end < 0) end = s.length;
		var start:int = end - 1;
		if (start < 0) return s;
		while ((start >= 0) && (digits.indexOf(s.charAt(start)) >= 0)) start--;
		return s.slice(start + 1, end);
	}

	private function installImagesAndSounds(objList:Array):void {
		// Install the images and sounds for the given list of ScratchObj objects.
		for each (var obj:ScratchObj in objList) {
			for each (var c:ScratchCostume in obj.costumes) {
				if (images[c.baseLayerID] != undefined) c.baseLayerData = images[c.baseLayerID];
				if (images[c.textLayerID] != undefined) c.textLayerData = images[c.textLayerID];
			}
			for each (var snd:ScratchSound in obj.sounds) {
				var sndData:* = sounds[snd.soundID];
				if (sndData) {
					snd.soundData = sndData;
					snd.convertMP3IfNeeded();
				}
			}
		}
	}

	private static function addCallServerErrorInfo(param1:Object) : Object
	{
		var _loc3_:* = null;
		var _loc2_:Object = Server.getInstance().callServerErrorInfo;
		if(_loc2_)
		{
			for(_loc3_ in _loc2_)
			{
				if(_loc2_.hasOwnProperty(_loc3_))
				{
					param1[_loc3_] = _loc2_[_loc3_].toString();
				}
			}
		}
		else
		{
			param1["errorEvent"] = "[no event]";
		}
		return param1;
	}

	// Load all images in all costumes from their image data, then call whenDone.
	public function decodeAllImages(objList:Array, whenDone:Function, fail:Function = null):void {
		// This should be called on success or failure of each image
		function imageDone():void {
			if (--numImagesToDecode == 0) {
				allImagesLoaded(objList, imageDict, whenDone, fail);
			}
		}

		var numImagesToDecode:int = 1; // start at 1 to prevent early finish
		var imageDict:Dictionary = new Dictionary(); // maps image data to BitmapData
		for each (var obj:ScratchObj in objList) {
			for each (var c:ScratchCostume in obj.costumes) {
				if ((c.baseLayerData != null) && (c.baseLayerBitmap == null)) {
					++numImagesToDecode;
					if (ScratchCostume.isSVGData(c.baseLayerData)) {
						decodeSVG(c.baseLayerData, imageDict, imageDone);
					}
					else {
						decodeImage(c.baseLayerData, imageDict, imageDone, imageDone);
					}
				}
				if ((c.textLayerData != null) && (c.textLayerBitmap == null)) {
					++numImagesToDecode;
					decodeImage(c.textLayerData, imageDict, imageDone, imageDone);
				}
			}
		}
		// decrement the artificial 1 and also handle the case where no images are present.
		imageDone();
	}

	private function allImagesLoaded(objList:Array, imageDict:Dictionary, whenDone:Function, fail:Function):void {
		var errorCostumes:Vector.<ScratchCostume> = new Vector.<ScratchCostume>(2);

		function makeErrorImage(obj:ScratchObj, c:ScratchCostume):* {
			if (!errorDialog) {
				errorDialog = new DialogBox();
				errorDialog.addTitle(translationStrings.imageLoadingErrorTitle);
				errorDialog.addText(Translator.map(translationStrings.imageLoadingErrorHeader) +'\n');
			}

			var itemText:String;
			if (obj.isStage) {
				itemText = Translator.map(translationStrings.imageLoadingErrorBackdrop);
			}
			else {
				itemText = Translator.map(translationStrings.imageLoadingErrorSprite) + '\n' +
						Translator.map(translationStrings.imageLoadingErrorCostume);
			}

			var context:Dictionary = new Dictionary();
			context['spriteName'] = obj.objName;
			context['costumeName'] = c.costumeName;
			itemText = StringUtils.substitute(itemText, context);
			errorDialog.addText(itemText + '\n');

			var errorCostumeIndex:int = int(obj.isStage);
			var errorCostume:ScratchCostume = errorCostumes[errorCostumeIndex] =
					errorCostumes[errorCostumeIndex] || ScratchCostume.emptyBitmapCostume('', obj.isStage);
			return errorCostume.baseLayerBitmap;
		}

		var allCostumes:Vector.<ScratchCostume> = new <ScratchCostume>[];
		var errorDialog:DialogBox;
		var img:*; // either BitmapData or SVGElement

		for each (var obj:ScratchObj in objList) {
			for each (var c:ScratchCostume in obj.costumes) {
				allCostumes.push(c);
				if ((c.baseLayerData != null) && (c.baseLayerBitmap == null)) {
					img = imageDict[c.baseLayerData];
					if (!img) {
						c.baseLayerBitmap = makeErrorImage(obj, c);
						c.baseLayerData = null;
					}
					else if (img is BitmapData) {
						c.baseLayerBitmap = img;
					}
					else if (img is SVGElement) {
						c.setSVGRoot(img, false);
					}
				}
				if ((c.textLayerData != null) && (c.textLayerBitmap == null)) {
					img = imageDict[c.textLayerData];
					if (img) {
						c.textLayerBitmap = imageDict[c.textLayerData];
					}
					else {
						c.textLayerBitmap = makeErrorImage(obj, c);
						c.textLayerData = null;
					}
				}
			}
		}
		for each (c in allCostumes) {
			c.generateOrFindComposite(allCostumes);
		}

		if (errorDialog) {
			errorDialog.addButton('OK', errorDialog.accept);
			errorDialog.showOnStage(Scratch.app.stage);

			if (fail != null) {
				fail();
			}
			else if (whenDone != null) {
				whenDone();
			}
		}
		else {
			if (whenDone != null) {
				whenDone();
			}
		}
	}

	private function decodeImage(imageData:ByteArray, imageDict:Dictionary, doneFunction:Function, fail:Function):void {
		function loadDone(e:Event):void {
			imageDict[imageData] = e.target.content.bitmapData;
			doneFunction();
		}
		function loadError(e:Event):void {
			if (fail != null) fail();
		}
		if (imageDict[imageData] != null) return; // already loading or loaded
		if (!imageData || imageData.length == 0) {
			if (fail != null) fail();
			return;
		}
		var loader:Loader = new Loader();
		loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadDone);
		loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, loadError);
		loader.loadBytes(imageData);
	}

	private function decodeSVG(svgData:ByteArray, imageDict:Dictionary, doneFunction:Function):void {
		function loadDone(svgRoot:SVGElement):void {
			imageDict[svgData] = svgRoot;
			doneFunction();
		}
		if (imageDict[svgData] != null) {
			// already loading or loaded
			doneFunction();
			return;
		}
		var importer:SVGImporter = new SVGImporter(XML(svgData));
		if (importer.hasUnloadedImages()) {
			importer.loadAllImages(loadDone);
		} else {
			loadDone(importer.root);
		}
	}

	public function downloadProjectAssets(projectData:ByteArray):void {
		function assetReceived(md5:String, data:ByteArray):void {
			assetDict[md5] = data;
			assetCount++;
			if (!data) {
				app.log(LogLevel.WARNING, 'missing asset: ' + md5);
			}
			if (app.lp) {
				app.lp.setProgress(assetCount / assetsToFetch.length);
				app.lp.setInfo(
						assetCount + ' ' +
								Translator.map('of') + ' ' + assetsToFetch.length + ' ' +
								Translator.map('assets loaded'));
			}
			if (assetCount == assetsToFetch.length) {
				installAssets(proj.allObjects(), assetDict);
				app.runtime.decodeImagesAndInstall(proj);
			}
		}
		projectData.position = 0;
		var projObject:Object = util.jsons.parse(projectData.readUTFBytes(projectData.length));
		var proj:ScratchStage = getScratchStage();
		proj.readJSON(projObject);
		var assetsToFetch:Array = collectAssetsToFetch(proj.allObjects());
		var assetDict:Object = new Object();
		var assetCount:int = 0;
		for each (var md5:String in assetsToFetch) fetchAsset(md5, assetReceived);
	}

	//----------------------------
	// Fetch a costume or sound from the server
	//----------------------------

	public function fetchImage(id:String, costumeName:String, width:int, whenDone:Function, otherData:Object = null):URLLoader {
		// Fetch an image asset from the server and call whenDone with the resulting ScratchCostume.
		var c:ScratchCostume;
		function gotCostumeData(data:ByteArray):void {
			if (!data) {
				app.log(LogLevel.WARNING, 'Image not found on server: ' + id);
				return;
			}
			if (ScratchCostume.isSVGData(data)) {
				if (otherData && otherData.centerX)
					c = new ScratchCostume(costumeName, data, otherData.centerX, otherData.centerY, otherData.bitmapResolution);
				else
					c = new ScratchCostume(costumeName, data);
				c.baseLayerMD5 = id;
				whenDone(c);
			} else {
				var loader:Loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, imageLoaded);
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, imageError);
				loader.loadBytes(data);
			}
		}
		function imageError(event:IOErrorEvent):void {
			app.log(LogLevel.WARNING, 'ProjectIO failed to load image', {id: id});
		}
		function imageLoaded(e:Event):void {
			if (otherData && otherData.centerX)
				c = new ScratchCostume(costumeName, e.target.content.bitmapData, otherData.centerX, otherData.centerY, otherData.bitmapResolution);
			else
				c = new ScratchCostume(costumeName, e.target.content.bitmapData);
			if (width) c.bitmapResolution = c.baseLayerBitmap.width / width;
			c.baseLayerMD5 = id;
			whenDone(c);
		}
		return app.server.getAsset(id, gotCostumeData);
	}

	public function fetchSound(id:String, sndName:String, whenDone:Function):void {
		// Fetch a sound asset from the server and call whenDone with the resulting ScratchSound.
		function gotSoundData(sndData:ByteArray):void {
			if (!sndData) {
				app.log(LogLevel.WARNING, 'Sound not found on server', {id: id});
				return;
			}
			var snd:ScratchSound;
			try {
				snd = new ScratchSound(sndName, sndData); // try reading data as WAV file
			} catch (e:*) { }
			if (snd && (snd.sampleCount > 0)) { // WAV data
				whenDone(snd);
			} else { // try to read data as an MP3 file
				MP3Loader.convertToScratchSound(sndName, sndData, whenDone);
			}
		}
		app.server.getAsset(id, gotSoundData);
	}

	//----------------------------
	// Download a sprite from the server
	//----------------------------

	public function fetchSprite(md5AndExt:String, whenDone:Function):void {
		// Fetch a sprite with the md5 hash.
		function jsonReceived(data:ByteArray):void {
			if (!data) return;
			spr.readJSON(util.jsons.parse(data.readUTFBytes(data.length)));
			spr.instantiateFromJSON(app.stagePane);
			fetchSpriteAssets([spr], assetsReceived);
		}
		function assetsReceived(assetDict:Object):void {
			installAssets([spr], assetDict);
			decodeAllImages([spr], done);
		}
		function done():void {
			spr.showCostume(spr.currentCostumeIndex);
			spr.setDirection(spr.direction);
			whenDone(spr);
		}
		var spr:ScratchSprite = new ScratchSprite();
		app.server.getAsset(md5AndExt, jsonReceived);
	}

	private function fetchSpriteAssets(objList:Array, whenDone:Function):void {
		// Download all media for the given list of ScratchObj objects.
		function assetReceived(md5:String, data:ByteArray):void {
			if (!data) {
				app.log(LogLevel.WARNING, 'missing sprite asset', {md5: md5});
			}
			assetDict[md5] = data;
			assetCount++;
			if (assetCount == assetsToFetch.length) whenDone(assetDict);
		}
		var assetDict:Object = new Object();
		var assetCount:int = 0;
		var assetsToFetch:Array = collectAssetsToFetch(objList);
		for each (var md5:String in assetsToFetch) fetchAsset(md5, assetReceived);
	}

	private function collectAssetsToFetch(objList:Array):Array {
		// Return list of MD5's for all project assets.
		var list:Array = new Array();
		for each (var obj:ScratchObj in objList) {
			for each (var c:ScratchCostume in obj.costumes) {
				if (list.indexOf(c.baseLayerMD5) < 0) list.push(c.baseLayerMD5);
				if (c.textLayerMD5) {
					if (list.indexOf(c.textLayerMD5) < 0) list.push(c.textLayerMD5);
				}
			}
			for each (var snd:ScratchSound in obj.sounds) {
				if (list.indexOf(snd.md5) < 0) list.push(snd.md5);
			}
		}
		return list;
	}

	private function installAssets(objList:Array, assetDict:Object):void {
		var data:ByteArray;
		for each (var obj:ScratchObj in objList) {
			for each (var c:ScratchCostume in obj.costumes) {
				data = assetDict[c.baseLayerMD5];
				if (data) c.baseLayerData = data;
				else {
					// Asset failed to load so use an empty costume
					// BUT retain the original MD5 and don't break the reference to the costume that failed to load.
					var origMD5:String = c.baseLayerMD5;
					c.baseLayerData = ScratchCostume.emptySVG();
					c.baseLayerMD5 = origMD5;
				}
				if (c.textLayerMD5) c.textLayerData = assetDict[c.textLayerMD5];
			}
			for each (var snd:ScratchSound in obj.sounds) {
				data = assetDict[snd.md5];
				if (data) {
					snd.soundData = data;
					snd.convertMP3IfNeeded();
				} else {
					snd.soundData = WAVFile.empty();
				}
			}
		}
	}

	public function fetchAsset(md5:String, whenDone:Function):URLLoader {
		return app.server.getAsset(md5, function(data:*):void { whenDone(md5, data); });
	}

	//----------------------------
	// Record unique images and sounds
	//----------------------------

	protected function recordImagesAndSounds(objList:Array, uploading:Boolean, proj:ScratchStage = null):void {
		var recordedAssets:Object = {};
		images = [];
		sounds = [];

		app.clearCachedBitmaps();
		if (!uploading && proj) proj.penLayerID = recordImage(proj.penLayerPNG, proj.penLayerMD5, recordedAssets, uploading);

		for each (var obj:ScratchObj in objList) {
			for each (var c:ScratchCostume in obj.costumes) {
				c.prepareToSave(); // encodes image and computes md5 if necessary
				c.baseLayerID = recordImage(c.baseLayerData, c.baseLayerMD5, recordedAssets, uploading);
				if (c.textLayerBitmap) {
					c.textLayerID = recordImage(c.textLayerData, c.textLayerMD5, recordedAssets, uploading);
				}
			}
			for each (var snd:ScratchSound in obj.sounds) {
				snd.prepareToSave(); // compute md5 if necessary
				snd.soundID = recordSound(snd, snd.md5, recordedAssets, uploading);
			}
		}
	}

	public function convertSqueakSounds(scratchObj:ScratchObj, done:Function):void {
		// Pre-convert any Squeak sounds (asynch, with a progress bar) before saving a project.
		// Note: If this is not called before recordImagesAndSounds(), sounds will
		// be converted synchronously, but there may be a long delay without any feedback.
		function convertASound():void {
			if (i < soundsToConvert.length) {
				var sndToConvert:ScratchSound = soundsToConvert[i++] as ScratchSound;
				sndToConvert.prepareToSave();
				app.lp.setProgress(i / soundsToConvert.length);
				app.lp.setInfo(sndToConvert.soundName);
				setTimeout(convertASound, 50);
			} else {
				app.removeLoadProgressBox();
				// Note: Must get user click in order to proceed with saving...
				DialogBox.notify('', 'Sounds converted', app.stage, false, soundsConverted);
			}
		}
		function soundsConverted(ignore:*):void { done() }
		var soundsToConvert:Array = [];
		for each (var obj:ScratchObj in scratchObj.allObjects()) {
			for each (var snd:ScratchSound in obj.sounds) {
				if ('squeak' == snd.format) soundsToConvert.push(snd);
			}
		}
		var i:int;
		if (soundsToConvert.length > 0) {
			app.addLoadProgressBox('Converting sounds...');
			setTimeout(convertASound, 50);
		} else done();
	}

	private function recordImage(img:*, md5:String, recordedAssets:Object, uploading:Boolean):int {
		var id:int = recordedAssetID(md5, recordedAssets, uploading);
		if (id > -2) return id; // image was already added
		images.push([md5, img]);
		id = images.length - 1;
		recordedAssets[md5] = id;
		return id;
	}

	protected function recordedAssetID(md5:String, recordedAssets:Object, uploading:Boolean):int {
		var id:* = recordedAssets[md5];
		return id != undefined ? id : -2;
	}

	private function serverHasAsset(param1:String) : Boolean
	{
		return param1 in serverAssets;


	}

	private function recordSound(snd:ScratchSound, md5:String, recordedAssets:Object, uploading:Boolean):int {
		var id:int = recordedAssetID(md5, recordedAssets, uploading);
		if (id > -2) return id; // image was already added
		sounds.push([md5, snd.soundData]);
		id = sounds.length - 1;
		recordedAssets[md5] = id;
		return id;
	}

	public function uploadProject(param1:ScratchStage, param2:String, param3:Boolean, param4:Function) : void
	{
		var projectJSON:String = null;
		var projectDataSaved:Boolean = false;
		var info:String = null;
		var allAssetsUploaded:Function = null;
		var projectSaved:Function = null;
		var timerTask:Function = null;
		var proj:ScratchStage = param1;
		var projectID:String = param2;
		var createNew:Boolean = param3;
		var onSuccess:Function = param4;
		allAssetsUploaded = function():void
		{
			Server.getInstance().setProject(projectID,projectJSON,projectSaved);
		};
		projectSaved = function(param1:String):void
		{
			//Scratch.app.externalCall("console.log('" + didUploadSucceed(param1) +"')");
			if(didUploadSucceed(param1))
			{
				projectDataSaved = true;
				app.removeLoadProgressBox();
				proj.clearPenLayer();
				//app.setSaveStatus("Saved");
				onSuccess(param1);
			}
			else
			{
				app.logMessage("Project save failed.",addCallServerErrorInfo({
					"response":param1,
					"data":projectJSON
				}));
				app.removeLoadProgressBox();
				Scratch.app.saveFailed();
			}
		};
		timerTask = function():void
		{
			if(projectDataSaved)
			{
				return;
			}
			if(app.lp)
			{
				info = info + "*";
				if(info.length > 10)
				{
					info = "*";
				}
				app.lp.setInfo(info);
				
				setTimeout(timerTask,500);
			}
		};
		delete proj.info.penTrails;
		proj.savePenLayer();
		proj.updateInfo();
		recordImagesAndSounds(proj.allObjects(),true);
		var hadProjectID:Boolean = projectID && projectID.length > 0;
		createNew = false
		projectJSON = util.JSON.stringify(proj);
		// Scratch.app.externalCall("console.log('" + projectJSON +"')");
		projectDataSaved = false;
		info = "*";
		//Scratch.app.setSaveStatus("Saving...");
		if(images.length + sounds.length > 0)
		{
			app.addLoadProgressBox("Saving changes...");
		}
		this.uploadImagesAndSounds(allAssetsUploaded);
		timerTask();
	}

	public function uploadSprite(param1:ScratchSprite, param2:Function) : void
	{
		var spriteJSONSaved:Function = null;
		var allAssetsUploaded:Function = null;
		var assetsSaved:Boolean = false;
		var jsonSaved:Boolean = false;
		var md5:String = null;
		var spr:ScratchSprite = param1;
		var onSuccess:Function = param2;
		spriteJSONSaved = function():void
		{
			jsonSaved = true;
			checkDone();
		};
		allAssetsUploaded = function():void
		{
			assetsSaved = true;
			checkDone();
		};
		var checkDone:Function = function():void
		{
			if(jsonSaved && assetsSaved)
			{
				Scratch.app.removeLoadProgressBox();
				onSuccess(md5 + ".json");
			}
		};
		Scratch.app.addLoadProgressBox("Uploading sprite...");
		recordImagesAndSounds([spr],true);
		this.uploadImagesAndSounds(allAssetsUploaded);
		var jsonData:ByteArray = new ByteArray();
		jsonData.writeUTFBytes(util.jsons.stringify(spr));
		md5 = MD5.hashBytes(jsonData);
		this.uploadAsset(md5,".json",jsonData,spriteJSONSaved);
	}

	private function recordServerAsset(param1:String) : void
	{
		serverAssets[param1] = null;
	}

	private function didUploadSucceed(param1:String, param2:String = "") : Boolean
	{
		var _loc3_:* = true;
		var _loc4_:* = undefined;
		if(param1)
		{
			if(true == true)
			{
				return true;
			}
			if(param1 == "true")
			{
				return true;
			}
			_loc3_ = param1.indexOf("<html>") > -1;
			_loc4_ = {};
			try
			{	
				_loc4_ = util.JSON.parse(param1);
				Scratch.app.externalCall("console.log('" +_loc4_ +"')");
			}
			catch(e:*)
			{
			}
			if(_loc4_.status == "ok")
			{
				return true;
			}
			if(_loc4_.status == "unauthorized" || _loc3_)
			{
				Scratch.app.externalCall('login')
				return false;
			}
		}
		return false;
	}

	private function uploadImagesAndSounds(param1:Function) : void
	{
		var assetUploadDone:Function = null;
		var i:int = 0;
		var md5:String = null;
		var data:ByteArray = null;
		var ext:String = null;
		var totalAssets:int = 0;
		var uploaded:int = 0;
		var whenDone:Function = param1;
		assetUploadDone = function():void
		{
			uploaded++;
			if(app.lp)
			{
				app.lp.setProgress(uploaded / totalAssets);
				app.lp.setInfo(uploaded + " of " + totalAssets + " assets uploaded");
			}
			if(uploaded == totalAssets)
			{
				whenDone();
			}
		};
		totalAssets = images.length + sounds.length;
		if(totalAssets == 0)
		{
			whenDone();
		}
		uploaded = 0;
		i = 0;
		while(i < images.length)
		{
			md5 = images[i][0];
			data = images[i][1];
			ext = ScratchCostume.fileExtension(data);
			this.uploadAsset(md5,ext,data,assetUploadDone);
			i++;
		}
		i = 0;
		while(i < sounds.length)
		{
			md5 = sounds[i][0];
			data = sounds[i][1];
			this.uploadAsset(md5,".wav",data,assetUploadDone);
			i++;
		}
	}


	public function uploadAsset(param1:String, param2:String, param3:ByteArray, param4:Function) : void
	{
		var uploadDone:Function = null;
		var md5:String = param1;
		var dotExt:String = param2;
		var data:ByteArray = param3;
		var whenDone:Function = param4;
		uploadDone = function(param1:String):void
		{
			if(didUploadSucceed(param1,md5))
			{
				recordServerAsset(md5);
				whenDone();
			}
			else
			{
				app.removeLoadProgressBox();
				Scratch.app.saveFailed();
			}
		};
		if(data.length == 0)
		{
			app.log(LogLevel.WARNING,"Skipping upload of empty asset",{
				"md5":md5,
				"dotExt":dotExt
			});
			whenDone();
			return;
		}
		if(md5.indexOf(".") < 0)
		{
			md5 = md5 + dotExt;
		}
		Server.getInstance().setAsset(md5,data,uploadDone);
	}
}}
