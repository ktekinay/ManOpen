
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <libc.h>        // for getopt()
#import <ctype.h>       // for isdigit()
#import <mach-o/dyld.h> // for _NSGetExecutablePath()
#import "MOAppSelection.h"

static NSString * const ManOpenBundleIdentifier = @"org.clindberg.ManOpen";
static CFStringRef const ManOpenPortName = CFSTR("8D98N325TG.org.clindberg.ManOpen.MachIPC");


static NSString *MakeNSStringFromPath(const char *filename)
{
    NSFileManager *manager = [NSFileManager defaultManager];
    return [manager stringWithFileSystemRepresentation:filename length:strlen(filename)];
}

static NSString *MakeAbsolutePath(const char *filename)
{
    NSString *currFile = MakeNSStringFromPath(filename);

    if (![currFile isAbsolutePath])
    {
        currFile = [[[NSFileManager defaultManager] currentDirectoryPath]
                     stringByAppendingPathComponent:currFile];
    }

    return currFile;
}

/* A copy of ManOpen at `url`, or nil if it isn't one. */
static MOAppCandidate *CandidateForURL(NSURL *url)
{
    NSBundle *bundle = (url != nil) ? [NSBundle bundleWithURL:url] : nil;

    if (![bundle.bundleIdentifier isEqualToString:ManOpenBundleIdentifier])
        return nil;
    return [MOAppCandidate candidateWithURL:url version:[bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
}

/* The ManOpen this tool is embedded in (Contents/Helpers/openman), following symlinks
   such as /usr/local/bin/openman to the real file. nil for a standalone copy. */
static MOAppCandidate *OwnApp(void)
{
    char path[PATH_MAX];
    char resolved[PATH_MAX];
    uint32_t size = sizeof(path);

    if (_NSGetExecutablePath(path, &size) != 0 || realpath(path, resolved) == NULL)
        return nil;
    return CandidateForURL(MOEnclosingAppBundle(MakeNSStringFromPath(resolved)));
}

/* Every copy of ManOpen that Launch Services knows about, in its order. */
static NSArray<MOAppCandidate *> *InstalledApps(void)
{
    NSArray<NSURL *> *urls = CFBridgingRelease(LSCopyApplicationURLsForBundleIdentifier((__bridge CFStringRef)ManOpenBundleIdentifier, NULL));
    NSMutableArray<MOAppCandidate *> *apps = [NSMutableArray array];

    for (id url in urls)
    {
        MOAppCandidate *candidate = [url isKindOfClass:[NSURL class]] ? CandidateForURL(url) : nil;
        if (candidate != nil)
            [apps addObject:candidate];
    }
    return apps;
}

/* Every running copy of ManOpen. */
static NSArray<MOAppCandidate *> *RunningApps(void)
{
    NSMutableArray<MOAppCandidate *> *apps = [NSMutableArray array];

    for (NSRunningApplication *app in [NSRunningApplication runningApplicationsWithBundleIdentifier:ManOpenBundleIdentifier])
    {
        MOAppCandidate *candidate = CandidateForURL(app.bundleURL);
        if (candidate != nil)
            [apps addObject:candidate];
    }
    return apps;
}

/* Launches the app at `url`, or brings it forward if it's already running. */
static BOOL OpenApp(NSURL *url, BOOL activate)
{
    NSWorkspaceOpenConfiguration *configuration = [NSWorkspaceOpenConfiguration configuration];
    dispatch_semaphore_t done = dispatch_semaphore_create(0);
    __block BOOL opened = NO;

    configuration.activates = activate;
    [[NSWorkspace sharedWorkspace] openApplicationAtURL:url configuration:configuration completionHandler:^(NSRunningApplication *app, NSError *error) {
        opened = (app != nil);
        dispatch_semaphore_signal(done);
    }];
    dispatch_semaphore_wait(done, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC));
    return opened;
}

/* Waits up to `seconds` for a launched ManOpen to start listening; the caller releases the port. */
static CFMessagePortRef CreateManOpenPort(double seconds)
{
    CFMessagePortRef port = NULL;

    // Check often: ManOpen waits only briefly before showing its Title panel at launch.
    for (double waited = 0.0; port == NULL && waited <= seconds; waited += 0.05)
    {
        port = CFMessagePortCreateRemote(NULL, ManOpenPortName);
        if (port == NULL)
            usleep(50000);
    }
    return port;
}

static void usage(const char *progname)
{
    fprintf(stderr,"%s: [-bk] [-M path] [-f file] [section] [name ...]\n", progname);
}

int main (int argc, char * const *argv)
{
	@autoreleasepool
	{
		NSString          *manPath = nil;
		NSString          *section = nil;
		NSMutableArray    *files = [NSMutableArray array];
		BOOL              aproposMode = NO;
		BOOL              forceToFront = YES;
		int               argIndex;
		int               c; // int, not char: getopt() returns -1 at the end
        NSMutableDictionary *distributedDictionary = [[NSMutableDictionary alloc] init];
        NSMutableArray    *namesAndSections = [[NSMutableArray alloc] init];
        CFMessagePortRef  remotePort;
        SInt32            status;
        BOOL              bringRunningAppForward = NO;
        NSData            *request;
		
		while ((c = getopt(argc,argv,"hbm:M:f:kaCcw")) != EOF)
		{
			switch(c)
			{
				case 'm':
				case 'M':
					manPath = MakeNSStringFromPath(optarg);
					break;
				case 'f':
					[files addObject:MakeAbsolutePath(optarg)];
					break;
				case 'b':
					forceToFront = NO;
					break;
				case 'k':
					aproposMode = YES;
					break;
				case 'a':
				case 'C':
				case 'c':
				case 'w':
					// MacOS X man(1) options; no-op here.
					break;
				case 'h':
				case '?':
				default:
					usage(argv[0]);
					exit(0);
			}
		}
		
		if (optind >= argc && [files count] <= 0)
		{
			usage(argv[0]);
			exit(0);
		}
		
		if (optind < argc && !aproposMode)
		{
			NSString *tmp = MakeNSStringFromPath(argv[optind]);
			
			if (isdigit(argv[optind][0])          ||
				/* These are configurable in /etc/man.conf; these are just the default strings.  Hm, they are invalid as of Panther. */
				[tmp isEqualToString:@"system"]   ||
				[tmp isEqualToString:@"commands"] ||
				[tmp isEqualToString:@"syscalls"] ||
				[tmp isEqualToString:@"libc"]     ||
				[tmp isEqualToString:@"special"]  ||
				[tmp isEqualToString:@"files"]    ||
				[tmp isEqualToString:@"games"]    ||
				[tmp isEqualToString:@"miscellaneous"] ||
				[tmp isEqualToString:@"misc"]     ||
				[tmp isEqualToString:@"admin"]    ||
				[tmp isEqualToString:@"n"]        || // Tcl pages on >= Panther
				[tmp isEqualToString:@"local"])
			{
				section = tmp;
				optind++;
			}
		}
		
		if (optind >= argc)
		{
			if ([section length] > 0)
			{
				/* MacOS X assumes it's a man page name */
				section = nil;
				optind--;
			}
			
			if (optind >= argc && [files count] <= 0)
			{
				exit(0);
			}
		}
		
        remotePort = CFMessagePortCreateRemote(NULL, ManOpenPortName);
        if (remotePort != NULL)
        {
            // A ManOpen that accepts requests is already running: launch nothing.
            // (Our environment, PAGER included, doesn't matter to it; ManOpen sets its own for man.)
            // It's brought forward only after the request is sent (below).
            bringRunningAppForward = forceToFront;
        }
        else
        {
            // Launch our own app if we're embedded in one, otherwise the best compatible copy.
            NSURL *appURL = MOChooseManOpenApp(OwnApp(), InstalledApps(), NSHomeDirectory());

            if (appURL == nil)
            {
                fprintf(stderr, "openman: ManOpen %s or later is required, but no copy of it was found.\n", MOMinimumCompatibleVersion.UTF8String);
                exit(1);
            }
            if (!OpenApp(appURL, forceToFront))
            {
                fprintf(stderr, "openman: could not launch %s\n", appURL.path.fileSystemRepresentation);
                exit(1);
            }

            remotePort = CreateManOpenPort(10.0);
            if (remotePort == NULL)
            {
                fprintf(stderr, "openman: could not connect to ManOpen at %s\n", appURL.path.fileSystemRepresentation);
                exit(1);
            }
        }

        if (files.count)
            distributedDictionary[@"Files"] = files;
        
		if (manPath == nil && getenv("MANPATH") != NULL)
			manPath = MakeNSStringFromPath(getenv("MANPATH"));
		
		for (argIndex = optind; argIndex < argc; argIndex++)
		{
			NSString *currFile = MakeNSStringFromPath(argv[argIndex]);
            NSDictionary *nameAndSection;
            
            if (section)
                nameAndSection = @{@"Name": currFile, @"Section": section};
            else
                nameAndSection = @{@"Name": currFile};
            [namesAndSections addObject:nameAndSection];
		}
		if (aproposMode)
            distributedDictionary[@"Apropos"] = @YES;
        if (manPath)
            distributedDictionary[@"ManPath"] = manPath;
        distributedDictionary[@"NamesAndSections"] = namesAndSections;
        
        // Once we've got all our data together, send the message to the app. The message ID below is intentional, because I feel like I went mental writing this (it was my third attempt at replacing the original DO code).
        request = [NSKeyedArchiver archivedDataWithRootObject:distributedDictionary requiringSecureCoding:YES error:NULL];
        status = (request != nil) ? CFMessagePortSendRequest(remotePort, 5150, (__bridge CFDataRef)request, 10.0, 10.0, bringRunningAppForward ? kCFRunLoopDefaultMode : NULL, NULL) : kCFMessagePortTransportError;
        CFRelease(remotePort);

        if (status != kCFMessagePortSuccess)
        {
            fprintf(stderr, "openman: could not send the request to ManOpen (error %d)\n", (int)status);
            exit(1);
        }

        // Bringing a running app forward sends it a "reopen" event, as a Dock click does. Sent
        // before the request, it arrived while ManOpen had no windows, and with "Open title panel
        // when no windows" on, the Title panel opened under the page. With a reply mode, the send
        // waits until ManOpen has handled the request, so the page's window is open by now.
        if (bringRunningAppForward)
        {
            NSURL *running = MOChooseManOpenApp(nil, RunningApps(), NSHomeDirectory());
            if (running != nil)
                OpenApp(running, YES);
        }
	}
    exit(0);       // insure the process exit status is 0
    return 0;      // ...and make main fit the ANSI spec.
}
