package ru.kubline.preloader.controllers {
import flash.display.Loader;
import flash.display.MovieClip;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.net.URLRequest;
import flash.system.LoaderContext;

/**
 * контроллер отвечает за загрузку и
 * отображение просьбы добавить приложение себе на страницу или разрешить все действия
 */
public class UserRequestController extends EventDispatcher {

    public static const ADD_APP_REQUESTS:int = 1;

    public static const SET_APP_SETTINGS_REQUESTS:int = 2;

    /**
     * базовый URL где лежит приложение
     */
    private var baseUrl:String;

    /**
     * Контекст загрузки ресурсов приложения
     */
    private var context:LoaderContext;

    /**
     * URL по которому лежит заставка
     */
    private var screenSaverUrl:String;

    /**
     * URL по которому лежит просьба добавить приложение на свою страницу
     */
    private var addAppRequestUrl:String;

    /**
     * URL по которому лежит  просьба разрешить все действия приложению
     */
    private var setAppSettingsRequestsUrl:String;

    /**
     *  инстанс заставки
     */
    private var screenSaver:MovieClip;

    /**
     * просьба добавить приложение на свою страницу
     */
    private var addAppRequest:MovieClip;

    /**
     * просьба разрешить все действия приложению
     */
    private var setAppSettingsRequests:MovieClip;

    private var loader:Loader;

    /**
     * тип просьбы
     */
    private var type:int = ADD_APP_REQUESTS;

    /**
     * @param context контекст для загрузки ресурсов
     * @param baseUrl базовый URL где лежит приложение
     */
    public function UserRequestController(context:LoaderContext, baseUrl:String, type:int) {
        this.context = context;
        this.baseUrl = baseUrl;
        this.screenSaverUrl = baseUrl + "data/interface/simpleScreenSaver.swf?2";
        this.addAppRequestUrl = baseUrl +  "data/interface/requests/addAppRequests.swf?2";
        this.setAppSettingsRequestsUrl = baseUrl + "data/interface/requests/setAppSettingsRequests.swf?2";
        this.type = type;
    }

    public function init(): void {
        loader = new Loader();
        loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onCompleteScreenSaverLoader);
        loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, ioErrorListener);
        loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorListener);
        loader.load(new URLRequest(screenSaverUrl), context);
    }

    private function onCompleteScreenSaverLoader(event:Event):void {
        screenSaver = MovieClip(event.target.content);
        screenSaver.x = 0;
        screenSaver.y = 2;
        loader = new Loader();
        loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, ioErrorListener);
        loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorListener);
        if(type == ADD_APP_REQUESTS){
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onAddAppRequestLoader);
            loader.load(new URLRequest(addAppRequestUrl), context);
        } else {
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onSetAppSettingsRequestsLoader);
            loader.load(new URLRequest(setAppSettingsRequestsUrl), context);
        }
    }

    private function onAddAppRequestLoader(event:Event) : void {
        addAppRequest = MovieClip(event.target.content);
        addAppRequest.x = 56;
        addAppRequest.y = 13;
        Preloader.instance.addChildAt(addAppRequest, 0);
        Preloader.instance.addChildAt(screenSaver, 0);
        Preloader.deleteScreenSaver();
    }

    private function onSetAppSettingsRequestsLoader(event:Event) : void {
        setAppSettingsRequests = MovieClip(event.target.content);
        setAppSettingsRequests.x = 0;
        setAppSettingsRequests.y = 0;
        Preloader.instance.addChildAt(setAppSettingsRequests, 0);
        Preloader.instance.addChildAt(screenSaver, 0);
        Preloader.deleteScreenSaver();
    }

    public function securityErrorListener(e:SecurityErrorEvent): void {
        dispatchEvent(e);
    }

    public function ioErrorListener(e:IOErrorEvent): void {
        dispatchEvent(e);
    }
}
}