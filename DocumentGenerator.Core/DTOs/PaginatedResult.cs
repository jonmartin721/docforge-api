namespace DocumentGenerator.Core.DTOs
{
    /// <summary>
    /// Represents a paginated result set.
    /// </summary>
    /// <typeparam name="T">The type of items in the result.</typeparam>
    public class PaginatedResult<T>
    {
        public IEnumerable<T> Items { get; set; } = Enumerable.Empty<T>();
        public int Page { get; set; }
        public int PageSize { get; set; }
        public int TotalCount { get; set; }
        public int TotalPages => PageSize > 0 ? (int)Math.Ceiling(TotalCount / (double)PageSize) : 0;
        public bool HasPreviousPage => Page > 1;
        public bool HasNextPage => Page < TotalPages;

        public PaginatedResult() { }

        public PaginatedResult(IEnumerable<T> items, int totalCount, int page, int pageSize)
        {
            Items = items;
            TotalCount = totalCount;
            Page = page;
            PageSize = pageSize;
        }

        /// <summary>
        /// Creates a paginated result from a queryable source.
        /// </summary>
        public static PaginatedResult<T> Create(IEnumerable<T> items, int totalCount, int page, int pageSize)
        {
            return new PaginatedResult<T>(items, totalCount, page, pageSize);
        }
    }
}
