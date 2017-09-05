
function ajaxCallback(value){
    console.log("content size :" + value.length);
    return value.length;
}
function parse(url1, url2){
    console.log([url1, url2]);
    ajax(url1,"ajaxCallback");
    return 0;
}
