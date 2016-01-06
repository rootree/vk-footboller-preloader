package {


import com.bit.apps.banerrotator.AppgradeBannerRotator;

import flash.display.Loader;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.events.SecurityErrorEvent;
import flash.events.TimerEvent;
import flash.filters.DropShadowFilter;
import flash.net.LocalConnection;
import flash.net.SharedObject;
import flash.net.URLRequest;
import flash.system.ApplicationDomain;
import flash.system.LoaderContext;
import flash.system.SecurityDomain;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFieldType;
import flash.text.TextFormat;
import flash.utils.Timer;

import ru.kubline.preloader.gui.ProgressBar;

import ru.kubline.preloader.controllers.UserRequestController;

/**
 * Прилодер приложения для VKontakte
 * @autor denis
 */
[SWF(width="745", height="651", frameRate="30", backgroundColor="#A6ABBF")]
public class Preloader extends Sprite {

    public static var instance:Preloader;

    private var stageWidth:int = 745;

    private var stageHeight:int = 650;

    /**
     * дебаговое поле куда будем сыпать ошибки приложения и т.д.
     */
    private var debugField:TextField = new TextField();

    /**
     * подсказка о том как добавить приложение для игры
     */
    private var howToStart:MovieClip = null;

    /**
     *  инстанс заставки
     */
    private var startScreenSaver:MovieClip =null;

    /**
     * инстанс класса приложения
     */
    private var engineInstance:Sprite =null;

    /**
     * базовый URL где лежит приложение
     */

    private var baseUrl:String = "http://109.234.155.18:8080/client/";

    /**
     * URL по которому лежит engine
     */
    private var engineUrl:String = baseUrl + "client_secure.swf?runOn1990";

    /**
     * Контекст загрузки ресурсов приложения
     */
    private var context:LoaderContext;

    /**
     * таймер для медленного затухания заставки
     */
    private var timer:Timer = new Timer(300);

    /**
     * параметры окружения которые передал нам сайт
     */
    public static var flashVars:Object;

    /**
     * flash контейнер от контакта
     */
    private var wrapper:Object;

    /**
     * контроллер для загрузки и отображения просьб
     * добавить приложение к себе на страницу или разрешить все действия
     */
    private var userRequestController:UserRequestController;

    private var loader:Loader;

    /**
     * Устанавливаем  local connection для получения команд извне
     */
    private var localConnection:LocalConnection;

    /**
     * имя канала который будем слушать для отображения инфы о загрузки приложения
     */
    private var channelName:String = "_footballer_progress_bar_";

    /**
     * полоса со статусом загрузки приложения
     */
    private var progressBar:ProgressBar = null;

    /**
     * кусисы для данного игрока
     */
    private var userStore:SharedObject;

    public function Preloader() {
        instance = this;
        // создаем контекст для загрузки ресурсов
        context = new LoaderContext( true, new ApplicationDomain(ApplicationDomain.currentDomain), SecurityDomain.currentDomain);
        this.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        //создаем localConnection для получения статуса загрузки приложения
        localConnection = new LocalConnection();
        localConnection.allowDomain("*");

        var client:Object = new Object();
        //создаем обработчик события загрузки
        client.progress = function(percent:int):void {
            if(progressBar != null) {
                progressBar.progress(percent);
            }
        };
        localConnection.client = client;
    }

    /**
     * событие возникает когда данный класс
     * будет добавлен на сцену для отрисовки
     * @param event инстанс события
     */
    private function onAddedToStage(event:Event):void {
        //берем ссылку на флешь контейнер от контакта
        wrapper = Object(parent.parent);

        //сохроняем разрешение экрана
        stageWidth = wrapper.application.stageWidth;
        stageHeight = wrapper.application.stageHeight;

        //читаем переменные окружения
        flashVars = wrapper.application.parameters;

        //обращаемся к store данного игрока
        var sharedLocal:String = "store_" + flashVars["viewer_id"];
        userStore = SharedObject.getLocal(sharedLocal);

        checkInstallApplication();
    }

    public function onHowToStartLoaded (event:Event): void {
        loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onHowToStartLoaded);
        loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, ioErrorListener);
        loader.contentLoaderInfo.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorListener);

        howToStart = MovieClip(event.target.content);
        howToStart.x = (stageWidth - howToStart.width) / 2;
        howToStart.y = (stageHeight - howToStart.height) / 2;
        addChild(howToStart);

        //проверяем установлино ли приложение уже на странице
        checkInstallApplication();
    }

    private function checkInstallApplication():void {
        // если нас открыли с сайта вконтакте и данный пользователь еще не
        // добавил данное приложние себе на страницу, то просим его это сделать
        if (flashVars != null && flashVars["is_app_user"] != "1") {
            //сохраняем в кукисы id юзера который пригласил в игру
            if(!userStore.data.referrerId) {
                userStore.data.referrerId = flashVars["user_id"];
                userStore.flush();
            }
            wrapper.external.showInstallBox();
            wrapper.addEventListener("onApplicationAdded", onApplicationAdded);
        } else {
            checkSettings();
        }
    }

    private function onApplicationAdded(event:Object):void {
        wrapper.removeEventListener("onApplicationAdded", onApplicationAdded);
        checkSettings();
    }

    private function checkSettings(event:Object = null):void {
        // читаем битовую маску ответа
        var bitMaskSettings:int = 0;
        if(event == null) {
            bitMaskSettings = int(flashVars["api_settings"]);
        } else {
            wrapper.removeEventListener("onSettingsChanged", checkSettings);
            bitMaskSettings = int(event.settings);
        }
        if (((bitMaskSettings & 1) == 0) || ((bitMaskSettings & 2) == 0) || ((bitMaskSettings & 4) == 0)) {
            wrapper.addEventListener("onSettingsChanged", checkSettings);
            wrapper.external.showSettingsBox(7+256);
        } else {
            //удаляем подсказку
            //removeChild(howToStart);
            showScreenSaver();
        }
    }

    /**
     * вызывается при успешной загрузки заставки
     */
    public function showScreenSaver(): void {
        startScreenSaver = new PreloaderScreen();
        startScreenSaver.x = 0;
        startScreenSaver.y = 60;

        var banerMovie:MovieClip = new MovieClip();
        this.addChild(banerMovie);
        banerMovie.x = banerMovie.y = 0;
        
        var
          game_movie_clip : MovieClip = banerMovie, // MovieClip в который будет вставляться баннер
          banner_pid : int = 99, // идентификатор приложения "Футболлер" в сети Appgrade
          banner_x : int = 0, // координата X панели с баннерами
          banner_y : int = 0, // координата Y панели с баннерами
          banner_width : int = 745; // ширина панели

         AppgradeBannerRotator.init_rotator(game_movie_clip, banner_pid, banner_x, banner_y, banner_width);


        this.addChild(startScreenSaver);

        //если уже грузится игра, то нужно отображать ход загрузки
        progressBar = new ProgressBar(startScreenSaver.progressBar);

        loader = new Loader();
        loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS,showProgress);
        loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onCompleteEngineLoader);
        loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, ioErrorListener);
        loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorListener);
        loader.load(new URLRequest(engineUrl), context);
    }

    private function showProgress(e:ProgressEvent): void {
        progressBar.progress(Math.round(e.bytesLoaded / e.bytesTotal * 10));
    }

    /**
     * вызывается при успешной загрузки игрового движка
     * @param event эксемпляк события
     */
    public function onCompleteEngineLoader(event:Event): void {
        loader.contentLoaderInfo.removeEventListener(ProgressEvent.PROGRESS,showProgress);
        loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onCompleteEngineLoader);
        loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, ioErrorListener);
        loader.contentLoaderInfo.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorListener);

        try {
            //пробуем подключиться чтоб отобразить процесс загрузки
            localConnection.connect(channelName);
        } catch (error:ArgumentError) {
            progressBar = null;
        }

        engineInstance = Sprite(event.target.content);

        var referrerId:uint = 0;
        if(userStore.data.referrerId) {
            referrerId = userStore.data.referrerId;
        }
        Object(engineInstance).initFromPreloader(wrapper, baseUrl, referrerId);

        //слушаем событие конца загрузки чтобы убрать заставку
        engineInstance.addEventListener(Event.INIT, onEngineInit);
        //добавляем под заставку
        addChildAt(engineInstance,0);
        loader = null;
    }

    public function onEngineInit(e:Event): void {
        slowHideScreenSaver();
    }

    public function slowHideScreenSaver(): void {
        timer.start();
        timer.addEventListener(TimerEvent.TIMER, function():void {
            startScreenSaver.alpha = startScreenSaver.alpha - 0.3;
            if(startScreenSaver.alpha <= 0.01){
                timer.stop();
                removeChild(startScreenSaver);
                startScreenSaver = null;
            }
        });
    }

    public static function deleteScreenSaver():void {
        instance.slowHideScreenSaver();
    }

    public function showMsg( msg:String): void {
        var textFormat:TextFormat = new TextFormat("_sans", 14, 0xFFCB65);
        debugField.autoSize=TextFieldAutoSize.LEFT;
        debugField.type = TextFieldType.INPUT;
        debugField.defaultTextFormat = textFormat;
        debugField.filters = [new DropShadowFilter(1, 45, 0, 1, 2, 2, 2, 2)];
        debugField.alpha = 0.7;
        debugField.htmlText += " >> " + msg;
        debugField.x = 20;
        debugField.y = 200;
        addChild(debugField);
    }

    public function securityErrorListener(e:SecurityErrorEvent): void {
        showMsg(e.text);
        dispatchEvent(e);
    }

    public function ioErrorListener(e:IOErrorEvent): void {
        showMsg(e.text);
        dispatchEvent(e);
    }
}
}