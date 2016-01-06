package ru.kubline.preloader.gui {
import flash.display.DisplayObject;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFieldType;

public class ProgressBar {

    /**
     * объект маска
     */
    private var mask:DisplayObject;

    /**
     * макс ширина маски
     */
    private var maskMaxWidth:int;

    /**
     * макс занчение
     */
    private var maxValue:Number = 100;

    private var percentMsg:TextField;

    private var container:MovieClip;

    public function ProgressBar(container:MovieClip) {
        this.container = container;
        this.mask = container.getChildByName("mask_panel");
        this.maskMaxWidth = mask.width;
        this.percentMsg = container.getChildByName("percent") as TextField;
        progress(1);
    }

    public function progress(percent:int):void{
        percentMsg.text = percent +" %";
        mask.width = maskMaxWidth * percent / maxValue;
    }

}
}
