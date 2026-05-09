---
layout: null
permalink: /assets/js/search-data.js
---
window.searchData = [{% for post in site.posts %}{"title":{{ post.title | jsonify }},"url":{{ post.url | relative_url | jsonify }},"excerpt":{{ post.excerpt | strip_html | truncate: 200 | jsonify }},"category":{{ post.categories | first | jsonify }},"tags":{{ post.tags | join: " " | jsonify }}}{% unless forloop.last %},{% endunless %}{% endfor %}];
