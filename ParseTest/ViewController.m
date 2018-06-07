//
//  ViewController.m
//  ParseTest
//
//  Created by Victor Macintosh on 05/06/2018.
//  Copyright © 2018 Victor Semenchuk. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <UITableViewDelegate, UITableViewDataSource, NSXMLParserDelegate>

@property (weak, nonatomic) UITableView *tableView;
@property (retain, nonatomic) NSXMLParser *parser;
@property (retain, nonatomic) NSMutableArray *feeds;
@property (retain, nonatomic) NSMutableDictionary *item;
@property (retain, nonatomic) NSMutableString *myTitle;
@property (retain, nonatomic) NSMutableString *date;
@property (retain, nonatomic) NSString *element;
@property (weak, nonatomic) NSTimer *timer;
@property (weak, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (assign, nonatomic) NSUInteger time;

- (void)setupViews;
- (void)startParsing;
- (void)resetResults;
- (void)endLoading;
- (void)onTick;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupViews];
    [self startParsing];
    
}

- (void)setupViews {
    CGRect frame = self.view.frame;
    UITableView *tableView = [[UITableView alloc] initWithFrame:frame];
    [tableView setDelegate:self];
    [tableView setDataSource:self];
    [self.view addSubview:tableView];
    self.tableView = tableView;
    
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Refresh"
                                                                      style:UIBarButtonItemStyleDone
                                                                     target:self
                                                                     action:@selector(startParsing)];
    self.navigationItem.rightBarButtonItem = barButtonItem;
    
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityIndicator.color = UIColor.purpleColor;
    activityIndicator.center = self.view.center;
    self.activityIndicator = activityIndicator;
    [self.view addSubview:self.activityIndicator];
}

- (void)startParsing {
    [self resetResults];
    [self.activityIndicator startAnimating];
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval: 1.0
                                                  target: self
                                                selector:@selector(onTick)
                                                userInfo: nil repeats:NO];
    
    NSURL *url = [NSURL URLWithString:@"http://images.apple.com/main/rss/hotnews/hotnews.rss"];
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURLSessionDownloadTask *task = [session downloadTaskWithURL:url
                                                completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error == nil) {
            NSData *data = [NSData dataWithContentsOfURL:location];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.parser = [[NSXMLParser alloc] initWithData:data];
                [self.parser setDelegate:self];
                [self.parser setShouldResolveExternalEntities:NO];
                dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                dispatch_async(queue, ^{
                    [self.parser parse];
                });
            });
        } else {
            NSLog(@"Error: %@", [error localizedDescription]);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showErrorAlert];
            });
        }
        [session invalidateAndCancel];
    }];
    [task resume];
}

- (void)resetResults {
    self.feeds = [[NSMutableArray alloc] init];
    self.title = @"0";
    self.time = 0;
    [self.tableView reloadData];
}

- (void)endLoading {
    [self.activityIndicator stopAnimating];
    [self.timer invalidate];
}

- (void)onTick {
    self.time += 1;
    self.title = [NSString stringWithFormat:@"%lu", self.time];
}

//MARK:- UITableView delegate and datasource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.feeds.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:cellIdentifier];
    }
    cell.textLabel.text = [[self.feeds objectAtIndex:indexPath.row] objectForKey: @"title"];
    cell.detailTextLabel.text = [[self.feeds objectAtIndex:indexPath.row] objectForKey: @"pubDate"];
    return cell;
}

//MARK:- NSXMLParser delegate methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
                                        namespaceURI:(NSString *)namespaceURI
                                       qualifiedName:(NSString *)qName
                                        attributes:(NSDictionary *)attributeDict {
    self.element = elementName;
    
    if ([self.element isEqualToString:@"item"]) {
        self.item = [[NSMutableDictionary alloc] init];
        self.myTitle = [[NSMutableString alloc] init];
        self.date = [[NSMutableString alloc] init];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    
    if ([self.element isEqualToString:@"title"]) {
        [self.myTitle appendString:string];
    } else if ([self.element isEqualToString:@"pubDate"]) {
        [self.date appendString:string];
    }
    
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    
    if ([elementName isEqualToString:@"item"]) {
        [self.item setObject:self.myTitle forKey:@"title"];
        [self.item setObject:self.date forKey:@"pubDate"];
        [self.feeds addObject:[self.item copy]];
    }
    
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self endLoading];
        [self.tableView reloadData];
    });
}

//MARK:- Alert

- (void)showErrorAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                   message:@"Something went wrong"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK"
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction * _Nonnull action) {
                                                       //something here
                                                   }];
    [alert addAction:action];
    [self presentViewController:alert
                       animated:YES
                     completion:nil];
}


@end
