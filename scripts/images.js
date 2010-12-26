var nativeDimensions = function(img) {
  if (!img.data('dimensions')) {
    var offscreenImage = new Image();
    offscreenImage.src = img.attr('src');
    img.data('dimensions', {
      'x': offscreenImage.width,
      'y': offscreenImage.height
    });
  }
  return img.data('dimensions');
};

var positionLightbox = function() {
  var padding = 12; // $body_padding from styles.sass
  var minWidth = 640; // $width from styles.sass
  var img = $('.lightbox img');
  var orig = nativeDimensions(img);
  var page = {
    'x': ($(window).width() - padding - padding),
    'y': ($(window).height() - padding - padding)
  };
  var ratios = {
    'orig': (orig.x / orig.y),
    'page': (page.x / page.y)
  };
  var renderWidth = (ratios.orig >= ratios.page) ? page.x : (page.x * ratios.orig / ratios.page);

  img.css({
    width: renderWidth,
    left: (Math.max(padding, (padding + (page.x - renderWidth) / 2)) + 'px'),
    top: (Math.max(padding, (padding + (page.y - (renderWidth / ratios.orig)) / 2)) + 'px')
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

head.ready(function() {
  $('img.lightboxable').click(function() {
    showFullSizeImage($(this).attr('src'));
  });
  $(window).resize(positionLightbox);
});
