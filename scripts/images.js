var positionLightbox = function() {
  var padding = 10,
      img = $('.lightbox img'),
      pagewidth = $(window).width() - padding - padding,
      pageheight = $(window).height() - padding - padding,
      width = Math.min(pagewidth, img.width()),
      height = Math.min(pageheight, img.height());

  if (width / height > pagewidth / pageheight) {
    img.css({
      width: pagewidth
    });
  } else {
    img.css({
      width: pagewidth
    });
  }
  img.css({
    top: ((padding + (pageheight - height) / 2) + 'px'),
    left: ((padding + (pagewidth - width) / 2) + 'px')
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
