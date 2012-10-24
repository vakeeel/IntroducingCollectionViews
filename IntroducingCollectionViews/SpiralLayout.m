#import "SpiralLayout.h"
#import "ConferenceLayoutAttributes.h"

#define ITEM_SIZE 170

@interface SpiralLayout()

@property (nonatomic, assign) CGSize pageSize;
@property (nonatomic, assign) CGSize contentSize;
@property (nonatomic, assign) CGFloat radius;
@property (nonatomic, strong) NSArray *cellCounts;
@property (nonatomic, strong) NSArray *pageRects;
@property (nonatomic, assign) NSInteger pageCount;
@property (nonatomic, strong) NSMutableArray *deleteIndexPaths;

@end

@implementation SpiralLayout

-(void)prepareLayout
{
    [super prepareLayout];
    
    self.pageSize = self.collectionView.frame.size;
    _radius = (MIN((self.pageSize.width - ITEM_SIZE), (self.pageSize.height - ITEM_SIZE) * 1.2)) / 2 - 5;
    
    self.pageCount = [self.collectionView numberOfSections];
    
    NSMutableArray *counts = [NSMutableArray arrayWithCapacity:self.pageCount];
    NSMutableArray *rects = [NSMutableArray arrayWithCapacity:self.pageCount];
    for (int section = 0; section < self.pageCount; section++)
    {
        [counts addObject:@([self.collectionView numberOfItemsInSection:section])];
        [rects addObject:[NSValue valueWithCGRect:(CGRect){{section * self.pageSize.width, 0}, self.pageSize}]];
    }
    self.cellCounts = [NSArray arrayWithArray:counts];
    self.pageRects = [NSArray arrayWithArray:rects];
    
    self.contentSize = CGSizeMake(self.pageSize.width * self.pageCount, self.pageSize.height);
}

-(CGSize)collectionViewContentSize
{
    return self.contentSize;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return !CGSizeEqualToSize(self.pageSize, newBounds.size);
}

+ (Class)layoutAttributesClass
{
    return [ConferenceLayoutAttributes class];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)path
{
    UICollectionViewLayoutAttributes* attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:path];
    attributes.size = CGSizeMake(ITEM_SIZE, ITEM_SIZE);
    int count = [self cellCountForSection:path.section];
    CGFloat denominator = MAX(count - 1, 1);
    CGRect pageRect = [self.pageRects[path.section] CGRectValue];
    attributes.center = CGPointMake(CGRectGetMidX(pageRect) + (_radius * path.item / denominator) * cosf(3 * path.item * M_PI / denominator), CGRectGetMidY(pageRect) + (_radius * path.item / denominator) * sinf(3 * path.item * M_PI / denominator));
    CGFloat scale = 0.25 + 0.75 * (path.item / denominator);
    attributes.transform3D = CATransform3DMakeScale(scale, scale, 1);
    return attributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    ConferenceLayoutAttributes *attributes = [ConferenceLayoutAttributes layoutAttributesForSupplementaryViewOfKind:kind withIndexPath:indexPath];
    CGRect pageRect = [self.pageRects[indexPath.section] CGRectValue];
    attributes.size = CGSizeMake(pageRect.size.width, 50);
    attributes.center = CGPointMake(CGRectGetMidX(pageRect), 35);
    attributes.headerTextAlignment = NSTextAlignmentCenter;
    return attributes;
}

- (int)cellCountForSection:(NSInteger)section
{
    NSNumber *count = self.cellCounts[section];
    return [count intValue];
}

-(NSArray*)layoutAttributesForElementsInRect:(CGRect)rect
{
    int page = 0;
    NSMutableArray* attributes = [NSMutableArray array];
    for (NSValue *pageRect in self.pageRects)
    {
        if (CGRectIntersectsRect(rect, pageRect.CGRectValue))
        {
            int cellCount = [self cellCountForSection:page];
            for (int i = 0; i < cellCount; i++) {
                NSIndexPath* indexPath = [NSIndexPath indexPathForItem:i inSection:page];
                [attributes addObject:[self layoutAttributesForItemAtIndexPath:indexPath]];
            }
            
            // add header
            [attributes addObject:[self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:[NSIndexPath indexPathForItem:0 inSection:page]]];
        }
        
        page++;
    }
    
    return attributes;
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity
{
    int closestPage = roundf(proposedContentOffset.x / self.pageSize.width);
    if (closestPage < 0)
        closestPage = 0;
    if (closestPage >= self.pageCount)
        closestPage = self.pageCount - 1;
    
    return CGPointMake(closestPage * self.pageSize.width, proposedContentOffset.y);
}

- (void)prepareForCollectionViewUpdates:(NSArray *)updateItems
{
    [super prepareForCollectionViewUpdates:updateItems];
    
    self.deleteIndexPaths = [NSMutableArray array];
    for (UICollectionViewUpdateItem *update in updateItems)
    {
        if (update.updateAction == UICollectionUpdateActionDelete)
        {
            [self.deleteIndexPaths addObject:update.indexPathBeforeUpdate];
        }
    }
}

- (void)finalizeCollectionViewUpdates
{
    [super finalizeCollectionViewUpdates];
    self.deleteIndexPaths = nil;
}

- (UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    UICollectionViewLayoutAttributes *attributes = nil;//[super finalLayoutAttributesForDisappearingItemAtIndexPath:itemIndexPath];
    
    if ([self.deleteIndexPaths containsObject:itemIndexPath])
    {
        // Configure attributes ...
        if (!attributes)
            attributes = [self layoutAttributesForItemAtIndexPath:itemIndexPath];
        attributes.alpha = 0.0;
        attributes.center = CGPointMake(attributes.center.x, 0 - ITEM_SIZE);
    }
    
    return attributes;
}


@end
