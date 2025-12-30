# MCBDSHost Marketing Website

This is the marketing and documentation website for MCBDSHost - a professional web-based management solution for Minecraft Bedrock Dedicated Server.

## Overview

The marketing website is built with:
- **.NET 10** - Latest .NET framework
- **Blazor Static Web App** - Server-side rendering for optimal performance
- **Bootstrap 5** - Responsive design framework
- **Bootstrap Icons** - Icon library

## Features

### Pages

1. **Home** (`/`)
   - Hero section with call-to-action
   - Key features overview
   - Technology stack showcase
   - Deployment options
   - CTA section

2. **Features** (`/features`)
   - Detailed feature breakdown
   - Core management features
   - Player management capabilities
   - Backup & recovery options
   - Configuration management
   - Multi-platform support
   - Technical capabilities

3. **Get Started** (`/get-started`)
   - Windows Server deployment guide
   - Linux deployment instructions
   - Home server setup
   - System requirements
   - Access information
   - Quick start guides

### Design Elements

- **Responsive Design** - Works on desktop, tablet, and mobile
- **Modern UI** - Clean, professional interface
- **Gradient Backgrounds** - Eye-catching hero sections
- **Hover Effects** - Interactive card animations
- **Code Blocks** - Syntax-highlighted installation commands
- **Icons** - Bootstrap Icons throughout

## Running the Website

### Development

```bash
cd MCBDS.Marketing
dotnet run
```

Visit `https://localhost:5001` or `http://localhost:5000`

### Build for Production

```bash
dotnet build -c Release
dotnet publish -c Release
```

## Deployment Options

### Static Web App Hosting

The site can be deployed to:
- **Azure Static Web Apps**
- **GitHub Pages**
- **Netlify**
- **Vercel**
- **Any static hosting service**

### Docker Deployment

```bash
docker build -t mcbdshost-marketing -f MCBDS.Marketing/Dockerfile .
docker run -p 8080:8080 mcbdshost-marketing
```

### Azure Static Web Apps (Recommended)

1. Create an Azure Static Web App resource
2. Connect to your GitHub repository
3. Configure build settings:
   - App location: `/MCBDS.Marketing`
   - Output location: `wwwroot`
4. Deploy automatically on push

## Customization

### Branding

- Logo: Update in `MainLayout.razor`
- Colors: Modify CSS variables in `marketing.css`
- Favicon: Replace `wwwroot/favicon.png`

### Content

- Pages are in `Components/Pages/`
- Layout is in `Components/Layout/MainLayout.razor`
- Styles are in `wwwroot/css/marketing.css`

### Adding Pages

1. Create new `.razor` file in `Components/Pages/`
2. Add `@page` directive with route
3. Update navigation in `MainLayout.razor`

## Project Structure

```
MCBDS.Marketing/
??? Components/
?   ??? Layout/
?   ?   ??? MainLayout.razor        # Main layout with nav and footer
?   ?   ??? MainLayout.razor.css
?   ?   ??? NavMenu.razor
?   ??? Pages/
?   ?   ??? Home.razor              # Landing page
?   ?   ??? Features.razor          # Features showcase
?   ?   ??? GetStarted.razor        # Installation guides
?   ?   ??? Error.razor
?   ?   ??? NotFound.razor
?   ??? App.razor                   # Root component
??? wwwroot/
?   ??? css/
?   ?   ??? marketing.css           # Custom marketing styles
?   ?   ??? app.css                 # Base styles
?   ??? favicon.png
??? Program.cs                       # Application entry point
??? MCBDS.Marketing.csproj          # Project file
```

## SEO Optimization

The site includes:
- Meta descriptions
- Keywords
- Semantic HTML
- Proper heading hierarchy
- Alt text for images (when added)
- Sitemap (can be generated)
- robots.txt (can be added)

## Performance

- Static site generation for fast load times
- Optimized CSS with minimal dependencies
- Bootstrap CDN for icons
- Code splitting with Blazor
- Lazy loading support

## Browser Support

- Chrome/Edge (latest)
- Firefox (latest)
- Safari (latest)
- Mobile browsers

## Contributing

To contribute to the marketing site:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally
5. Submit a pull request

## License

This marketing website is part of the MCBDSHost project and is licensed under the MIT License.

## Contact

- **GitHub**: https://github.com/JoshuaBylotas/MCBDSHost
- **Issues**: https://github.com/JoshuaBylotas/MCBDSHost/issues
- **Discussions**: https://github.com/JoshuaBylotas/MCBDSHost/discussions

---

Built with ?? using .NET 10 and Blazor
