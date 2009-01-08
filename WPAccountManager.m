/* $Id$ */

/*
 *  Copyright (c) 2003-2009 Axel Andersson
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *  1. Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *  2. Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#import "WPAccountManager.h"

@interface WPAccountManager(Private)

- (NSMutableArray *)_readUserAccounts;

@end


@implementation WPAccountManager(Private)

- (NSMutableArray *)_readUserAccounts {
	NSEnumerator		*enumerator;
	NSMutableArray		*accounts;
	NSArray				*account;
	NSString			*file, *line;
	
	accounts		= [NSMutableArray array];
	file			= [NSString stringWithContentsOfFile:_usersPath];
	enumerator		= [[file componentsSeparatedByString:@"\n"] objectEnumerator];
	
	while((line = [enumerator nextObject])) {
		if([line hasPrefix:@"#"])
			continue;
		
		account = [line componentsSeparatedByString:@":"];
		
		if([account count] > 3)
			[accounts addObject:[[account mutableCopy] autorelease]];
	}
	
	return accounts;
}



- (BOOL)_writeUserAccounts:(NSArray *)accounts error:(WPError **)error {
	NSEnumerator		*enumerator;
	NSMutableString		*string;
	NSArray				*account;
	
	string = [NSMutableString string];

	[string appendFormat:[NSSWF:@"# This file was generated by %@ at %@\n", 
		[[self bundle] objectForInfoDictionaryKey:@"CFBundleExecutable"],
		[_dateFormatter stringFromDate:[NSDate date]]]];
	
	enumerator = [accounts objectEnumerator];
	
	while((account = [enumerator nextObject]))
		[string appendFormat:@"%@\n", [account componentsJoinedByString:@":"]];
	
	return [[string dataUsingEncoding:NSUTF8StringEncoding] writeToFile:_usersPath options:NSAtomicWrite error:(NSError **) &error];
}

@end



@implementation WPAccountManager

- (id)initWithUsersPath:(NSString *)usersPath groupsPath:(NSString *)groupsPath {
	self = [super init];
	
	_usersPath		= [usersPath retain];
	_groupsPath		= [groupsPath retain];
	
	_dateFormatter = [[WIDateFormatter alloc] init];
	[_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	[_dateFormatter setDateStyle:NSDateFormatterShortStyle];

	return self;
}



- (void)dealloc {
	[_usersPath release];
	[_groupsPath release];
	
	[_dateFormatter release];
	
	[super dealloc];
}



#pragma mark -

- (BOOL)hasUserAccountWithName:(NSString *)name password:(NSString **)password {
	NSEnumerator		*enumerator;
	NSMutableArray		*account;
	
	enumerator = [[self _readUserAccounts] objectEnumerator];
	
	while((account = [enumerator nextObject])) {
		if([[account objectAtIndex:0] isEqualToString:name]) {
			*password = [account objectAtIndex:1];
			
			return YES;
		}
	}
	
	return NO;
}



#pragma mark -

- (BOOL)setPassword:(NSString *)password forUserAccountWithName:(NSString *)name andWriteWithError:(WPError **)error {
	NSEnumerator		*enumerator;
	NSMutableArray		*accounts, *account;
	
	accounts	= [NSMutableArray array];
	enumerator	= [[self _readUserAccounts] objectEnumerator];
	
	while((account = [enumerator nextObject])) {
		if([[account objectAtIndex:0] isEqualToString:name])
			[account replaceObjectAtIndex:1 withObject:[password SHA1]];
		
		[accounts addObject:account];
	}
	
	return [self _writeUserAccounts:accounts error:error];
}



- (BOOL)createNewAdminUserAccountWithName:(NSString *)name password:(NSString *)password andWriteWithError:(WPError **)error {
	NSEnumerator		*enumerator;
	NSMutableArray		*accounts;
	NSArray				*account;
	
	accounts	= [NSMutableArray array];
	enumerator	= [[self _readUserAccounts] objectEnumerator];
	account		= [[NSSWF:@"%@:%@::1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:1:0:0:0:0:1",
							name, [password SHA1]]
				   componentsSeparatedByString:@":"];
	
	[accounts addObject:account];
	
	while((account = [enumerator nextObject])) {
		if(![[account objectAtIndex:0] isEqualToString:name])
			[accounts addObject:account];
	}
	
	return [self _writeUserAccounts:accounts error:error];
}

@end
