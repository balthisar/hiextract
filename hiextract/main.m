//
//  main.m
//  hiextract
//
//  Created by Jim Derry on 6/4/18.
//  Copyright © 2018 Jim Derry. All rights reserved.
//  Released under the MIT License.
//

#import <Foundation/Foundation.h>
#import "HelpSDMIndex.h"


void usage( void )
{
    printf( "%s\n", "Usage: hiextract --help | [[option] helpindex_file]" );
    printf( "%s\n", " --text|xml|json  Export the wordlist as text (default), XML or JSON." );
    printf( "%s\n", " --help           Show this message and exit." );
    printf( "%s\n", " --version        Show the version and exit." );
    printf( "%s\n", "Output will go to stdout." );
}


void version( void )
{
    printf( "%s\n", "hiextract version 1.0. © 2018 by Jim Derry; All Rights Reserved. MIT License." );
}


void dictionaryToText( NSDictionary *dict )
{
    [[dict description] writeToFile:@"/dev/stdout" atomically:false encoding:NSUTF8StringEncoding error:NULL];
}


void dictionaryToXML( NSDictionary *dict )
{
    [dict writeToFile:@"/dev/stdout" atomically:false];
}


void dictionaryToJSON( NSDictionary *dict )
{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];

    if ( !jsonData )
    {
        NSString *message = [NSString stringWithFormat:@"JSON Serializer had an error: %@", error];
        [message writeToFile:@"/dev/stderr" atomically:false encoding:NSUTF8StringEncoding error:NULL];
    }
    else
    {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        [jsonString writeToFile:@"/dev/stdout" atomically:false encoding:NSUTF8StringEncoding error:NULL];
        printf( "\n" );
    }
}


int main( int argc, const char * argv[] )
{
    typedef enum _OutputType { TEXT, XML, JSON } OutputType;
    OutputType outputType = TEXT;

    @autoreleasepool
    {
        NSMutableArray *args = [[NSMutableArray alloc] initWithArray:NSProcessInfo.processInfo.arguments];
        [args removeObjectAtIndex:0];

        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *path = nil;

        while (args.count > 0)
        {
            if ( [[args[0] lowercaseString] isEqualToString:@"--help"] )
            {
                usage();
                exit(0);
            }

            if ( [[args[0] lowercaseString] isEqualToString:@"--version"] )
            {
                version();
                exit(0);
            }

            if ( [[args[0] lowercaseString] isEqualToString:@"--text"] )
            {
                outputType = TEXT;
                [args removeObjectAtIndex:0];
                continue;
            }

            if ( [[args[0] lowercaseString] isEqualToString:@"--xml"] )
            {
                outputType = XML;
                [args removeObjectAtIndex:0];
                continue;
            }

            if ( [[args[0] lowercaseString] isEqualToString:@"--json"] )
            {
                outputType = JSON;
                [args removeObjectAtIndex:0];
                continue;
            }

            if ( [fileManager isReadableFileAtPath:args[0]] )
            {
                path = args[0];
                break;
            }

            usage();
            exit(1);
        }

        if (!path)
        {
            usage();
            exit(0);
        }


        /* This dictionary is ready to use with the following keys:
         * - SKI_ANCHOR_DATA, which provides a useable NSDict already.
         * - SKI_USE_REMOTE_ROOT, which provides a useable char.
         * - SDMIndexData, which we need to use a private framework to access.
         * - SKI_VERSIONS, which provides a usable NSDict.
         * - SKI_INDEX_DATA, which we don't know how to access quite yet.
         */
        NSDictionary *dict = [NSUnarchiver unarchiveObjectWithFile:path];

        /* Get the SDMIndexData as an NSDictionary */
        HelpSDMIndex *SDMIndexInstance = [HelpSDMIndex HelpSDMIndexWithVersionedData:dict[@"SDMIndexData"]];
        NSDictionary *SDMIndex = SDMIndexInstance.indexData;

        switch ( outputType )
        {
            case TEXT:
                dictionaryToText( SDMIndex );
                break;
            case XML:
                dictionaryToXML( SDMIndex );
                break;
            case JSON:
                dictionaryToJSON( SDMIndex );
                break;
        }
    }
    return 0;
}
