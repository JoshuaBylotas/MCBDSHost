# Contact & Support Feature - Marketing Site

## ? Feature Complete!

The MCBDSHost marketing site now includes a comprehensive contact and support system.

---

## ?? Support Email

**Email Address:** `support@mc-bds.com`

All feedback and support requests will be directed to this email address.

---

## ?? New Contact Page (`/contact`)

### Features

1. **Contact Options Cards**
   - Email Support - Direct mailto link
   - Feedback Form - Interactive form
   - Documentation - Link to Get Started

2. **Feedback Form**
   - Name (required)
   - Email (required)
   - Subject dropdown (required):
     - Bug Report
     - Feature Request
     - Technical Support
     - General Feedback
     - Installation Help
     - Other
   - Message (required)
   - System Information (optional)
   - Submit button

3. **Form Behavior**
   - Opens user's default email client
   - Pre-fills recipient: `support@mc-bds.com`
   - Pre-fills subject line
   - Formats message with name, email, and content
   - Includes system information if provided
   - Shows alert after submission

4. **FAQ Section**
   - Bootstrap accordion with 5 common questions:
     - How do I install MCBDSHost?
     - What are the system requirements?
     - Where do I download Minecraft Bedrock Server?
     - How do I report a bug?
     - Is MCBDSHost free to use?

5. **Response Time Notice**
   - Alert box with expected response time (24-48 hours)
   - Headset icon for visual appeal

---

## ?? Design

### Styling
- Matches Minecraft theme
- Feature cards with icons (primary, success, info colors)
- Form with Bootstrap styling
- Accordion for FAQ
- Alert boxes for notices

### Icons
- ?? Envelope - Email support
- ?? Chat dots - Feedback
- ? Question circle - Documentation
- ? Clock - Response time
- ?? Headset - Support illustration

---

## ?? Integration Points

### 1. Navigation Bar
- Added "Contact" link between "Get Started" and end
- Accessible from all pages

### 2. Footer
- "Contact & Support" link in Quick Links section
- "Email Support" direct mailto link in Resources
- Support email displayed in bottom right: `support@mc-bds.com`

### 3. Home Page
- Can add "Contact Us" CTA if needed

---

## ?? Email Template

When users submit the form, the email will contain:

```
Subject: [User Selected Subject]

Name: [User Name]
Email: [User Email]

Message:
[User Message]

System Information:
[Optional System Info]

---
Sent from MCBDSHost Contact Form
```

---

## ?? User Journey

### Scenario 1: Bug Report
1. User encounters a bug
2. Navigates to Contact page
3. Fills form with "Bug Report" subject
4. Includes system information
5. Submits form
6. Email client opens with pre-filled message
7. User sends email to support@mc-bds.com

### Scenario 2: Quick Question
1. User has a question
2. Checks FAQ section first
3. If not answered, uses feedback form or direct email

### Scenario 3: Feature Request
1. User has an idea
2. Goes to Contact page
3. Selects "Feature Request" subject
4. Describes requested feature
5. Sends via form

---

## ?? Form Fields

### Required Fields
- **Name**: User's full name
- **Email**: Reply-to address
- **Subject**: Category of inquiry
- **Message**: Detailed description

### Optional Fields
- **System Information**: 
  - OS version
  - Docker version
  - MCBDSHost version
  - Minecraft server version
  - Error messages
  - Logs

---

## ?? Technical Implementation

### Form Handler (JavaScript)
```javascript
document.getElementById('contactForm').addEventListener('submit', function(e) {
    e.preventDefault();
    
    // Collect form data
    const name = document.getElementById('name').value;
    const email = document.getElementById('email').value;
    const subject = document.getElementById('subject').value;
    const message = document.getElementById('message').value;
    const systemInfo = document.getElementById('systemInfo').value;
    
    // Format email body
    let emailBody = `Name: ${name}\nEmail: ${email}\n\n`;
    emailBody += `Message:\n${message}\n\n`;
    
    if (systemInfo) {
        emailBody += `System Information:\n${systemInfo}\n\n`;
    }
    
    emailBody += `---\nSent from MCBDSHost Contact Form`;
    
    // Create mailto link
    const mailtoLink = `mailto:support@mc-bds.com?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(emailBody)}`;
    
    // Open email client
    window.location.href = mailtoLink;
    
    // Show confirmation
    alert('Your email client will open with a pre-filled message. Please review and send it.');
});
```

### Why Mailto?
- **No server required**: Static hosting compatible
- **No backend needed**: Pure frontend solution
- **User control**: Users review before sending
- **Privacy**: No data stored on server
- **Universal**: Works with any email client

---

## ?? Benefits

1. **Easy Support Access**
   - Multiple ways to contact (direct email, form)
   - Clear email address displayed
   - One-click email links

2. **Better UX**
   - Structured form with categories
   - Optional system info helps debugging
   - FAQ reduces support load

3. **Professional Appearance**
   - Dedicated contact page
   - Consistent Minecraft theming
   - Clear response time expectations

4. **Low Maintenance**
   - No backend infrastructure
   - No database required
   - Works with static hosting

---

## ?? Expected Usage

### Common Inquiries
1. **Installation Help** - 35%
2. **Bug Reports** - 25%
3. **Feature Requests** - 20%
4. **General Questions** - 15%
5. **Other** - 5%

### Response Strategy
- **24-48 hours**: Standard response time
- **URGENT tag**: Prioritize critical issues
- **FAQ updates**: Add common questions

---

## ?? Minecraft Theme Integration

### Feature Cards
- Block-style cards with shadows
- Icon badges with Minecraft colors
- Hover lift effects

### Form Styling
- Bordered inputs with shadows
- Primary button with press effect
- Alert boxes with themed colors

### FAQ Accordion
- Bootstrap accordion
- Smooth expand/collapse
- Themed colors

---

## ?? Content Guidelines

### Writing Effective Messages
Users should include:
- **Clear description**: What happened?
- **Steps to reproduce**: How to trigger the issue?
- **Expected behavior**: What should happen?
- **Actual behavior**: What actually happens?
- **System info**: OS, versions, logs
- **Screenshots**: If applicable (attach to email)

---

## ?? Future Enhancements

Potential additions:
- [ ] Server-side form submission
- [ ] Email verification
- [ ] File upload for logs/screenshots
- [ ] Live chat integration
- [ ] Support ticket system
- [ ] Status page for known issues
- [ ] Community forum integration

---

## ? Testing Checklist

- [ ] Contact page loads at /contact
- [ ] Navigation link works
- [ ] Footer links work
- [ ] Form validates required fields
- [ ] Email client opens on submit
- [ ] Pre-filled email is correct
- [ ] FAQ accordion expands/collapses
- [ ] Mobile responsive
- [ ] Email address is clickable
- [ ] Form resets after submission

---

## ?? Support Email Setup

To enable `support@mc-bds.com`, you'll need to:

1. **Register Domain**: mc-bds.com
2. **Setup Email**:
   - Use Google Workspace, Microsoft 365, or email hosting
   - Create `support@mc-bds.com` mailbox
3. **Configure Forwarders** (optional):
   - Forward to personal email
   - Setup auto-responder
4. **Email Signature**:
   ```
   MCBDSHost Support Team
   Email: support@mc-bds.com
   Documentation: https://yoursite.com/get-started
   ```

---

## ?? Key URLs

- **Contact Page**: `/contact`
- **Email**: `support@mc-bds.com`
- **Documentation**: `/get-started`
- **Features**: `/features`

---

## ?? Deployment

The updated marketing site packages include:
- New Contact.razor page
- Updated MainLayout with contact links
- All necessary styling
- Form JavaScript handler

### Deploy Steps
1. Extract updated static or full package
2. Upload to hosting
3. Verify `/contact` page works
4. Test email form submission
5. Update DNS if needed for custom domain

---

**Contact & Support Feature Complete!** ?

Users can now easily reach out for help via:
- ?? **Direct Email**: support@mc-bds.com
- ?? **Feedback Form**: /contact page
- ? **FAQ**: Self-service help
- ?? **Documentation**: Linked resources

The site is ready for user engagement and support! ??
