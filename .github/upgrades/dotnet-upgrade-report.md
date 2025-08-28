# .NET 9.0 Upgrade Report

## Project target framework modifications

| Project name              | Old Target Framework | New Target Framework | Commits                   |
|:--------------------------|:-------------------:|:-------------------:|---------------------------|
| ContosoUniversity.csproj  |   net48             | net9.0              | 91270797, f682ab11        |

## NuGet Packages

| Package Name                                   | Old Version | New Version | Status    |
|:-----------------------------------------------|:-----------:|:-----------:|-----------|
| Antlr                                         |   -         |  3.5.0.2    | Added     |
| Microsoft.Bcl.AsyncInterfaces                |   -         |  9.0.8      | Added     |
| Microsoft.Bcl.HashCode                       |   -         |  6.0.0      | Added     |
| Microsoft.Data.SqlClient                     |   -         |  6.1.1      | Added     |
| Microsoft.EntityFrameworkCore                |   3.1.32    |  9.0.8      | Updated   |
| Microsoft.EntityFrameworkCore.Abstractions   |   3.1.32    |  9.0.8      | Updated   |
| Microsoft.EntityFrameworkCore.Analyzers      |   3.1.32    |  9.0.8      | Updated   |
| Microsoft.EntityFrameworkCore.Relational     |   3.1.32    |  9.0.8      | Updated   |
| Microsoft.EntityFrameworkCore.SqlServer      |   3.1.32    |  9.0.8      | Updated   |
| Microsoft.EntityFrameworkCore.Tools          |   3.1.32    |  9.0.8      | Updated   |
| Microsoft.Extensions.Caching.Abstractions    |   3.1.32    |  9.0.8      | Updated   |
| Microsoft.Extensions.Caching.Memory          |   3.1.32    |  9.0.8      | Updated   |
| Microsoft.Extensions.Configuration           |   3.1.32    |  9.0.8      | Updated   |
| Microsoft.Extensions.Configuration.Abstractions |   3.1.32 |  9.0.8      | Updated   |
| Microsoft.Extensions.Configuration.Binder    |   3.1.32    |  9.0.8      | Updated   |
| Microsoft.Extensions.DependencyInjection     |   3.1.32    |  9.0.8      | Updated   |
| Microsoft.Extensions.DependencyInjection.Abstractions |   3.1.32 |  9.0.8  | Updated   |
| Microsoft.Extensions.Logging                 |   3.1.32    |  9.0.8      | Updated   |
| Microsoft.Extensions.Logging.Abstractions    |   3.1.32    |  9.0.8      | Updated   |
| Microsoft.Extensions.Options                 |   3.1.32    |  9.0.8      | Updated   |
| Microsoft.Extensions.Primitives              |   3.1.32    |  9.0.8      | Updated   |
| Microsoft.Identity.Client                    |   4.21.1    |  4.76.0     | Updated   |
| System.Collections.Immutable                 |   1.7.1     |  9.0.8      | Updated   |
| System.Configuration.ConfigurationManager    |   -         |  9.0.8      | Added     |
| Microsoft.AspNet.Mvc                         |   5.2.9     |  -          | Removed   |
| Microsoft.AspNet.Razor                       |   3.2.9     |  -          | Removed   |
| Microsoft.AspNet.Web.Optimization            |   1.1.3     |  -          | Removed   |
| Microsoft.AspNet.WebPages                    |   3.2.9     |  -          | Removed   |
| Microsoft.CodeDom.Providers.DotNetCompilerPlatform |   2.0.1 |  -      | Removed   |
| Microsoft.Web.Infrastructure                 |   2.0.1     |  -          | Removed   |

## All commits

| Commit ID | Description                                                    |
|:----------|:---------------------------------------------------------------|
| f82bb9b5 | Commit upgrade plan                                           |
| 91270797 | Migrate project to SDK-style and .NET 9; cleanup files      |
| 1ce2efc5 | System.Messaging feature upgrade completed                   |
| f682ab11 | Update ContosoUniversity.csproj dependencies to latest versions |
| 9f9ce0f9 | Global.asax.cs feature upgrade completed                     |
| bcb15413 | System.Web.Optimization bundling feature upgrade completed   |
| 2594d07d | Update package versions in ContosoUniversity.csproj         |
| c8910551 | RouteCollection feature upgrade completed                     |
| 5146bb52 | GlobalFilterCollection feature upgrade completed             |
| c79ede9c | Migrate to ASP.NET Core: remove MVC, update controllers     |
| e4dc42c6 | Store final changes for step                                 |
| 790b175d | Replace Server.MapPath with cross-platform compatible method |

## Project feature upgrades

Contains summary of modifications made to the project assets during different upgrade stages.

### ContosoUniversity.csproj

Here is what changed for the project during upgrade:

- **Project Conversion**: Converted from traditional .NET Framework project format to modern SDK-style project targeting .NET 9.0
- **System.Web.Optimization**: Bundling and minification feature upgrade completed - replaced all @Scripts.Render and @Styles.Render with direct HTML tags, removed BundleConfig and related references
- **RouteCollection**: Feature upgrade completed - default MVC route mapping added to Program.cs using app.MapControllerRoute
- **GlobalFilterCollection**: Feature upgrade completed - global error and status code handling moved to middleware and controller actions, StatusCode view added
- **System.Messaging**: Feature upgrade completed - converted to MSMQ.Messaging with dependency injection and updated configuration
- **Global.asax.cs**: Feature upgrade completed - application initialization moved to Program.cs with proper dependency injection setup
- **Entity Framework Core**: All EF Core packages upgraded from version 3.1.32 to 9.0.8
- **Security Updates**: Microsoft.Data.SqlClient upgraded from 2.1.4 to 6.1.1 to address security vulnerability (CVE-2024-0056)
- **ASP.NET Core Migration**: Migrated from System.Web.Mvc to Microsoft.AspNetCore.Mvc with updated controller patterns
- **Cross-platform Compatibility**: Replaced Server.MapPath with cross-platform compatible Directory.GetCurrentDirectory() and Path.Combine methods

## Next steps

- **Testing**: Run comprehensive testing to ensure all functionality works correctly in .NET 9.0
- **Performance**: Monitor application performance and optimize as needed
- **Deployment**: Update deployment scripts and configuration for .NET 9.0 hosting environment
- **Documentation**: Update project documentation to reflect the new .NET 9.0 architecture and dependencies