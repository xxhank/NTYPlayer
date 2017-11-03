/*
    native层和js层通信接口以及过程
    native层提供的接口:
        /// 异步请求数据
        ajax(url:String, requestID:String, callbackName:String, options:Object)
        options:
            header:{},
            method:POST|GET
            parameters:{}
            body:{}

        /// js完成后通知native层
        completion(result:Object)

        /// 用来输入日志
        console.log(message:String)
    js层提供的接口
       /// 流解析的黑盒子
        parse(url:String)
    流程
     1. native层调用parse
     2. js层调用ajax获取数据
     3. native层数据请求结束后调用callback方法
     4. js层所用请求结束后,调用completion接口通知native层

 */
var requests = [];
var result = {};

function ajaxCallback(id, value) {
    console.log("content size :" + value.length);

    var index =requests.indexOf(id);
    if (index != -1) {
        requests.splice(index, 1);
    }

    result[id] = value.length;

    if (requests.length == 0) {
        bridge_completion(result);
    }
    return  id + ":" + value.length;
}

function parse(url1, url2) {
    console.log([url1, url2]);
    requests.push("url1");
    requests.push("url2");
    bridge_ajax(url1, "url1", "ajaxCallback");
    bridge_ajax(url2, "url2", "ajaxCallback");

    var functionID  = bridge_testcalllback("xxxx", function(message){
        console.log("got message form native :" +message);
    });

    console.log("function id " + functionID);
    var timer = setTimeout(function(context){
        console.log("on timer" + context);
    }, 5000, "context");
    console.log("timer "+timer);

    return 0;
}
