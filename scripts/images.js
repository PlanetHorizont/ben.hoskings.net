var setNativeDimensions = function(img) {
  if (!img.data('dimensions')) {
    offscreenImage = new Image();
    offscreenImage.src = img.attr('src');
    img.data('dimensions', {
      'width': offscreenImage.width,
      'height': offscreenImage.height
    });
  }
  return img.data('dimensions');
};

var positionLightbox = function() {
  var padding = 12; // $body_padding from styles.sass
  var minWidth = 640; // $width from styles.sass
  var img = $('.lightbox img');
  var dims = setNativeDimensions(img);
  var pagewidth = $(window).width() - padding - padding;
  var pageheight = $(window).height() - padding - padding;
  var width = Math.max(minWidth, Math.min(pagewidth, dims.width));
  console.log("var width = Math.max(" + minWidth + ", Math.min(" + pagewidth + ", " + dims.width + "));")
  var height = Math.max(
    (minWidth * dims.height / width),
    Math.min(pageheight, dims.height)
  );

  console.log("if (" + width + " / " + height + " > " + pagewidth + " / " + pageheight + ")");
  if (width / height > pagewidth / pageheight) {
    console.log("img.css({width: " + width + "});");
    img.css({
      'width': width
    });
  } else {
    // img.css({
    //   width: pagewidth
    // });
  }
  img.css({
    top: (Math.max(padding, (padding + (pageheight - height) / 2)) + 'px'),
    left: (Math.max(padding, (padding + (pagewidth - width) / 2)) + 'px')
  });
};
var showFullSizeImage = function(uri) {
  $('.lightbox').remove();
  $('<div />').addClass('lightbox').append(
    $('<img />').addClass('original').attr('src', uri)
  ).appendTo('body').click(function() {
    $(this).remove();
  });
  positionLightbox();
};
$(function() {
  $('img').click(function() {
    showFullSizeImage($(this).attr('src'));
  });
  $(window).resize(positionLightbox);
});
