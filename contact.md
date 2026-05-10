---
layout: page
title: Contact
permalink: /contact/
---

<div class="page-wrap">
<div class="page-content">
<h1>Contact Us</h1>
<p>Have a question, feedback, or want to advertise on Owlno? We'd love to hear from you. Fill out the form below and we'll get back to you within 24 hours.</p>

<h2>Advertising &amp; Partnerships</h2>
<p>Owlno reaches a growing audience of engaged Australian readers. For advertising enquiries, sponsored content, or partnership opportunities, please use the form below and select "Advertising" as your subject.</p>

<h2>General Enquiries</h2>
<form class="page-form" action="https://formspree.io/f/xwvywbvj" method="POST">
<input type="text" name="name" placeholder="Your name" required>
<input type="email" name="email" placeholder="Your email address" required>
<input type="text" name="subject" placeholder="Subject">
<textarea name="message" placeholder="Your message..." required></textarea>
<input type="hidden" name="_next" value="https://www.owlno.com/contact/?thanks=true">
<button type="submit">Send Message</button>
</form>

<script>
if (window.location.search.indexOf('thanks=true') > -1) {
  document.querySelector('.page-form').style.display = 'none';
  var msg = document.createElement('p');
  msg.style.cssText = 'color:green;font-size:18px;font-weight:600;margin-top:20px;';
  msg.textContent = '✓ Message sent! We\'ll be in touch soon.';
  document.querySelector('.page-content').appendChild(msg);
}
</script>

</div>
</div>
