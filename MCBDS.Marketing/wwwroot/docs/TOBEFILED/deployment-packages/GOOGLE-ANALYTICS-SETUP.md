# Google Analytics & Support Email Integration

## ? Features Added

### ?? Google Analytics Tracking

**Tracking ID:** `G-6408KZLKH4`

All pages in the marketing site now include Google Analytics tracking.

---

## ?? Implementation

### 1. Global Tracking (All Pages)

**Location:** `MainLayout.razor` (in `<head>` section)

```html
<!-- Google tag (gtag.js) -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-6408KZLKH4"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());

  gtag('config', 'G-6408KZLKH4');
</script>
```

**Benefits:**
- ? Loads on every page automatically
- ? Tracks page views
- ? Tracks user sessions
- ? Tracks navigation patterns
- ? Available to custom events

---

## ?? What Gets Tracked

### Automatic Tracking

1. **Page Views**
   - Every page load
   - URL path
   - Page title
   - Referrer

2. **User Demographics**
   - Geographic location
   - Language
   - Device type (desktop/mobile/tablet)
   - Browser
   - Operating system

3. **Session Data**
   - Session duration
   - Pages per session
   - Bounce rate
   - New vs returning visitors

4. **Traffic Sources**
   - Direct traffic
   - Referral sources
   - Social media
   - Search engines

### Custom Event Tracking

**Contact Form Submission**
```javascript
gtag('event', 'contact_form_submit', {
    'event_category': 'engagement',
    'event_label': subject  // Bug Report, Feature Request, etc.
});
```

**Tracked Data:**
- When users submit the contact form
- What type of inquiry (subject)
- Helps understand user needs

---

## ?? Support Email Integration

### Updates to Contact Page

1. **Feedback Card**
   - Text updated: "All feedback goes to support@mc-bds.com"

2. **Alert Message**
   - Now mentions: "pre-filled message to **support@mc-bds.com**"
   - Direct link to email

3. **Submit Button**
   - Changed to: "Send to support@mc-bds.com"
   - Clear about destination

4. **Confirmation Alert**
   - Updated message: "...to support@mc-bds.com. Please review and send it."

---

## ?? Analytics Dashboard

### Access Your Analytics

1. **Sign in to Google Analytics**
   - Go to: https://analytics.google.com
   - Sign in with Google account
   - Select property: G-6408KZLKH4

2. **Available Reports**
   - **Realtime**: See live users on site
   - **Acquisition**: How users find your site
   - **Engagement**: Which pages are popular
   - **Demographics**: Who your users are
   - **Events**: Track custom actions

---

## ?? Key Metrics to Monitor

### Traffic Metrics
- **Page Views**: Total number of page loads
- **Users**: Unique visitors
- **Sessions**: Total visits
- **Bounce Rate**: % of single-page visits
- **Session Duration**: Average time on site

### Popular Pages
- Which pages get most traffic
- Which guides are most viewed
- Navigation patterns

### User Behavior
- Most common referrers
- Search terms (if available)
- Geographic distribution
- Device types

### Engagement
- Contact form submissions
- Subject categories (Bug Report, Feature Request, etc.)
- Download button clicks (can be added)

---

## ?? Custom Events You Can Add

### Download Tracking
```javascript
// Track download button clicks
gtag('event', 'download', {
    'event_category': 'downloads',
    'event_label': 'Windows Package'
});
```

### Navigation Clicks
```javascript
// Track important link clicks
gtag('event', 'click', {
    'event_category': 'navigation',
    'event_label': 'Get Started'
});
```

### External Links
```javascript
// Track external link clicks
gtag('event', 'outbound_link', {
    'event_category': 'external',
    'event_label': 'Minecraft Official'
});
```

---

## ?? Privacy Considerations

### What Analytics Collects
- ? Anonymous usage data
- ? Aggregate statistics
- ? No personally identifiable information
- ? No form contents captured

### GDPR Compliance
- Google Analytics is GDPR compliant
- IP anonymization enabled by default
- Users can opt-out via browser extensions
- No cookies required for basic tracking

### Privacy Policy (Recommended)
Consider adding a privacy policy page that mentions:
- Use of Google Analytics
- Anonymous data collection
- Purpose of tracking (improve user experience)
- Right to opt-out

---

## ?? Tracking Code Details

### Script Breakdown

1. **Async Loading**
   ```html
   <script async src="..."></script>
   ```
   - Non-blocking script load
   - Doesn't slow down page

2. **Data Layer**
   ```javascript
   window.dataLayer = window.dataLayer || [];
   ```
   - Queue for tracking events
   - Ensures no data loss

3. **gtag Function**
   ```javascript
   function gtag(){dataLayer.push(arguments);}
   ```
   - Main tracking function
   - Sends events to Google

4. **Configuration**
   ```javascript
   gtag('config', 'G-6408KZLKH4');
   ```
   - Sets up tracking ID
   - Enables automatic tracking

---

## ?? Using Analytics Data

### Optimize Content
- See which pages are most popular
- Identify confusing navigation
- Improve underperforming pages

### Understand Users
- Know where users come from
- Understand user needs via contact subjects
- Target marketing efforts

### Track Growth
- Monitor user growth over time
- See impact of marketing efforts
- Measure engagement improvements

---

## ?? Email Support Flow

### User Journey
1. User visits `/contact` page
2. Fills out feedback form
3. Selects subject (e.g., "Bug Report")
4. Clicks "Send to support@mc-bds.com"
5. Google Analytics tracks submission
6. Email client opens with pre-filled message
7. User sends to support@mc-bds.com

### Analytics View
In Google Analytics, you'll see:
- How many form submissions
- Which subjects are most common
- Conversion rate (visits to submissions)

---

## ?? Testing

### Verify Analytics Works

1. **Real-Time Report**
   - Visit your site
   - Go to Google Analytics ? Realtime
   - Should see yourself as active user

2. **Event Tracking**
   - Submit contact form (use test data)
   - Go to Events ? contact_form_submit
   - Verify event appears

3. **Page Tracking**
   - Navigate between pages
   - Check Realtime ? Overview
   - See page views update

---

## ?? Files Updated

1. **MainLayout.razor**
   - Added Google Analytics script in `<head>`
   - Applied to all pages automatically

2. **Contact.razor**
   - Updated text to mention support@mc-bds.com
   - Added analytics event tracking
   - Updated button text
   - Updated alert messages

---

## ?? Deployment

### Live Tracking
Once deployed:
- Analytics starts tracking immediately
- No additional configuration needed
- Data appears in Google Analytics dashboard within 24-48 hours

### Domain Verification
- If using custom domain, verify in Google Search Console
- Add property to Google Analytics
- Link properties for complete data

---

## ?? Sample Analytics Reports

### Week 1 Expected Metrics
- **Users**: 10-50 (initial visitors)
- **Sessions**: 20-100
- **Page Views**: 50-300
- **Top Pages**: Home, Get Started, Features
- **Contact Submissions**: 0-5

### Growth Indicators
- Increasing users week-over-week
- Lower bounce rate (< 70%)
- Higher pages per session (> 2)
- More contact submissions

---

## ? Checklist

Verify everything works:
- [ ] Google Analytics script loads on all pages
- [ ] Real-time report shows active users
- [ ] Page views are tracked
- [ ] Contact form submission tracked
- [ ] support@mc-bds.com mentioned on Contact page
- [ ] Email client opens with correct recipient
- [ ] No console errors

---

## ?? Useful Links

- **Google Analytics Dashboard**: https://analytics.google.com
- **Analytics Help**: https://support.google.com/analytics
- **Measurement ID**: G-6408KZLKH4
- **Support Email**: support@mc-bds.com

---

**Tracking Enabled!** ??

Your marketing site now has:
- ? **Google Analytics** tracking all user interactions
- ? **Contact Form** events tracked for engagement analysis
- ? **Support Email** clearly communicated to users
- ? **Professional** analytics setup for growth insights

Monitor your dashboard to understand user behavior and optimize the site! ??
