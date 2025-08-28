# .NET 9.0 Upgrade Plan

## Execution Steps

Execute steps below sequentially one by one in the order they are listed.

1. Validate that a .NET 9.0 SDK required for this upgrade is installed on the machine and if not, help to get it installed
2. Ensure that the SDK version specified in global.json files is compatible with the .NET 9.0 upgrade
3. Upgrade ContosoUniversity.csproj

## Settings

This section contains settings and data used by execution steps.

### Aggregate NuGet packages modifications across all projects

NuGet packages used across all selected projects or their dependencies that need version update in projects that reference them.

| Package Name                                    | Current Version | New Version | Description                         |
|:------------------------------------------------|:---------------:|:-----------:|:------------------------------------|
| Antlr                                          |   3.4.1.9004    |  4.6.6      | Package upgrade recommended         |
| Microsoft.AspNet.Mvc                          |   5.2.9         |  Remove     | Functionality included with framework |
| Microsoft.AspNet.Razor                        |   3.2.9         |  Remove     | Functionality included with framework |
| Microsoft.AspNet.Web.Optimization             |   1.1.3         |  Remove     | No supported version found          |
| Microsoft.AspNet.WebPages                     |   3.2.9         |  Remove     | Functionality included with framework |
| Microsoft.Bcl.AsyncInterfaces                 |   1.1.1         |  9.0.8      | Package upgrade recommended         |
| Microsoft.Bcl.HashCode                        |   1.1.1         |  6.0.0      | Package upgrade recommended         |
| Microsoft.CodeDom.Providers.DotNetCompilerPlatform |   2.0.1     |  Remove     | Functionality included with framework |
| Microsoft.Data.SqlClient                      |   2.1.4         |  6.1.1      | Security vulnerability              |
| Microsoft.EntityFrameworkCore                 |   3.1.32        |  9.0.8      | Package upgrade recommended         |
| Microsoft.EntityFrameworkCore.Abstractions    |   3.1.32        |  9.0.8      | Package upgrade recommended         |
| Microsoft.EntityFrameworkCore.Analyzers       |   3.1.32        |  9.0.8      | Package upgrade recommended         |
| Microsoft.EntityFrameworkCore.Relational      |   3.1.32        |  9.0.8      | Package upgrade recommended         |
| Microsoft.EntityFrameworkCore.SqlServer       |   3.1.32        |  9.0.8      | Package upgrade recommended         |
| Microsoft.EntityFrameworkCore.Tools           |   3.1.32        |  9.0.8      | Package upgrade recommended         |
| Microsoft.Extensions.Caching.Abstractions     |   3.1.32        |  9.0.8      | Package upgrade recommended         |
| Microsoft.Extensions.Caching.Memory           |   3.1.32        |  9.0.8      | Package upgrade recommended         |
| Microsoft.Extensions.Configuration            |   3.1.32        |  9.0.8      | Package upgrade recommended         |
| Microsoft.Extensions.Configuration.Abstractions |   3.1.32      |  9.0.8      | Package upgrade recommended         |
| Microsoft.Extensions.Configuration.Binder     |   3.1.32        |  9.0.8      | Package upgrade recommended         |
| Microsoft.Extensions.DependencyInjection      |   3.1.32        |  9.0.8      | Package upgrade recommended         |
| Microsoft.Extensions.DependencyInjection.Abstractions |   3.1.32 |  9.0.8      | Package upgrade recommended         |
| Microsoft.Extensions.Logging                  |   3.1.32        |  9.0.8      | Package upgrade recommended         |
| Microsoft.Extensions.Logging.Abstractions     |   3.1.32        |  9.0.8      | Package upgrade recommended         |
| Microsoft.Extensions.Options                  |   3.1.32        |  9.0.8      | Package upgrade recommended         |
| Microsoft.Extensions.Primitives               |   3.1.32        |  9.0.8      | Package upgrade recommended         |
| Microsoft.Identity.Client                     |   4.21.1        |  4.76.0     | Package is deprecated               |
| Microsoft.Web.Infrastructure                  |   2.0.1         |  Remove     | Functionality included with framework |
| NETStandard.Library                           |   2.0.3         |  Remove     | Functionality included with framework |
| System.Buffers                                |   4.5.1         |  Remove     | Functionality included with framework |
| System.Collections.Immutable                  |   1.7.1         |  9.0.8      | Package upgrade recommended         |
| System.ComponentModel.Annotations             |   4.7.0         |  Remove     | Functionality included with framework |
| System.Diagnostics.DiagnosticSource           |   4.7.1         |  9.0.8      | Package upgrade recommended         |
| System.Memory                                 |   4.5.4         |  Remove     | Functionality included with framework |
| System.Numerics.Vectors                       |   4.5.0         |  Remove     | Functionality included with framework |
| System.Runtime.CompilerServices.Unsafe        |   4.5.3         |  6.1.2      | Package upgrade recommended         |
| System.Threading.Tasks.Extensions             |   4.5.4         |  Remove     | Functionality included with framework |

### Project upgrade details

This section contains details about each project upgrade and modifications that need to be done in the project.

#### ContosoUniversity.csproj modifications

Project properties changes:
  - Convert project to SDK-style format
  - Target framework should be changed from `.NETFramework,Version=v4.8` to `net9.0`

NuGet packages changes:
  - Microsoft.Data.SqlClient should be updated from `2.1.4` to `6.1.1` (*security vulnerability*)
  - Microsoft.Identity.Client should be updated from `4.21.1` to `4.76.0` (*package is deprecated*)
  - All Entity Framework Core packages should be updated to `9.0.8` (*recommended for .NET 9.0*)
  - Multiple packages will be removed as their functionality is included with the framework
  - Antlr should be updated from `3.4.1.9004` to `4.6.6` (*package upgrade recommended*)

Feature upgrades:
  - System.Web.Optimization bundling and minification feature upgrade: Replace with direct HTML tags pointing to content files
  - RouteCollection feature upgrade: Convert route registration to application object route mappings
  - GlobalFilterCollection feature upgrade: Convert to middleware registrations on the application object
  - System.Messaging feature upgrade: Convert to MSMQ in .NET Core
  - Global.asax.cs feature upgrade: Convert application initialization code to .NET Core and clean up Global.asax.cs

Other changes:
  - Convert project file to SDK-style format
  - Update target framework from .NET Framework 4.8 to .NET 9.0