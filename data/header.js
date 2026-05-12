var url = new URL(window.location.href);
var page = url.searchParams.get("page");
console.log(page);

if (
  (typeof page === 'string' || page instanceof String) &&
    page.match(/^\d+$/) &&
    parseInt(page) >= 2
) {
  var redirect = new URL(`${url.pathname.replace(/\/$/, '')}/p${page}/`, url);
  window.location.href = redirect.href;
}
