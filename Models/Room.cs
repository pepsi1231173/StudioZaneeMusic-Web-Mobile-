namespace DuAnBai3.Models
{
    public class Room
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public string Type { get; set; } // STANDARD, VIP, SVIP
        public int MaxPeople { get; set; }

        public int WeekdayPrice { get; set; }
        public int WeekendPrice { get; set; }
        public int GoldenHourPrice { get; set; }

        // Thêm URL ảnh phòng
        public string ImageUrl { get; set; } = "/images/default_room.jpg"; // Có thể để default
    }
}
