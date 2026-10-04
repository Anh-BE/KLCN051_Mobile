# Tài liệu Hướng dẫn Phát triển App Mobile (Flutter)
**Dự án:** Quản lý đăng ký đề tài tốt nghiệp cho sinh viên (cử nhân, kỹ sư) - KLCN051  
**Nền tảng:** Mobile App (iOS & Android) - Ngôn ngữ: Dart / Framework: Flutter  
**Nguồn thiết kế mẫu:** Bộ 17 màn hình chuẩn ezHR Mobile (`C:\Users\Le Ngoc Anh\Desktop\anhthietke_appmobile`)

---

## 1. Cấu trúc thư mục cốt lõi (Folder Structure)
Hệ thống áp dụng kiến trúc chia theo tính năng (Feature-based) và tách biệt logic (UI vs Logic) để dễ bảo trì và mở rộng. Mọi code phát triển nằm trong thư mục `lib/`.

```text
lib/
 ├── core/                     # CHỨA CÁC THÀNH PHẦN DÙNG CHUNG TOÀN APP
 │   ├── constants/            # Các hằng số: Mã màu sắc (app_colors.dart), Link API (api_endpoints.dart)
 │   ├── network/              # Cấu hình gọi API (Dio/Http), chặn lỗi 401, tự động gắn Token
 │   ├── utils/                # Hàm tiện ích (lưu Token vào bộ nhớ, format ngày tháng...)
 │   └── widgets/              # UI Components tái sử dụng (Nút bấm, Ô nhập liệu, Dialog chuẩn)
 │
 ├── features/                 # CHIA THEO TỪNG CỤM TÍNH NĂNG & ACTOR
 │   │
 │   ├── auth/                 # Tính năng Đăng nhập (Chung cho mọi người dùng)
 │   │   ├── logic/            # Code xử lý gọi API, lưu Token, phân quyền
 │   │   └── view/             # Giao diện màn hình Login, AuthLayout
 │   │
 │   ├── main_layout/          # Khung giao diện chính sau khi đăng nhập (Bottom Navigation Bar 5 tabs)
 │   │
 │   ├── student/              # TÍNH NĂNG CHO SINH VIÊN
 │   │   ├── group/            # Quản lý nhóm (tạo nhóm, mời bạn)
 │   │   ├── topic/            # Đăng ký đề tài
 │   │   └── report/           # Nộp báo cáo tiến độ tuần
 │   │
 │   ├── lecturer/             # TÍNH NĂNG CHO GIẢNG VIÊN
 │   │   ├── topic_list/       # Xem danh sách đề tài đang hướng dẫn
 │   │   ├── review_report/    # Xem và nhận xét tiến độ
 │   │   └── grading/          # Nhập điểm bảo vệ theo CĐR
 │   │
 │   └── manager/              # TÍNH NĂNG CHO QUẢN LÝ (Ban chủ nhiệm)
 │       └── dashboard/        # Xem biểu đồ, số liệu tổng hợp thống kê
 │
 └── main.dart                 # File khởi chạy gốc của toàn bộ ứng dụng
```

---

## 2. Quy tắc lập trình cốt lõi (Coding Rules)
1. **Tách biệt Giao diện và Logic:** Không nhồi nhét xử lý gọi API hay tính toán phức tạp vào file `view`. Giao diện (`view`) chỉ dùng để hiển thị và lắng nghe sự kiện, phần xử lý phải gọi sang file `logic`.
2. **Layout & Tái sử dụng:** 
   - Những thành phần giao diện xuất hiện ở nhiều nơi (nút bấm chuẩn, ô text, thẻ card) bắt buộc phải tạo widget dùng chung trong `core/widgets/`.
   - Các màn hình bên trong app sẽ được bọc bởi `main_layout` để tái sử dụng thanh điều hướng.
3. **Màu sắc và Theme:** Tuyệt đối không hard-code mã màu (VD: `#196ec9`) vào từng file giao diện. Hãy gọi qua biến toàn cục `AppColors.primary` đã được định nghĩa trong `core/constants/app_colors.dart`.
4. **Gọi API:** Sử dụng chung file cấu hình từ `core/network/` để tận dụng tính năng tự động đính kèm JWT Token.

---

## 3. Sổ tay Hướng dẫn Thiết kế UI/UX (Design System Chi Tiết)

### 3.1. Bảng màu & Kiểu chữ (Color Palette & Typography)
- **Màu nhấn chính (Primary):** Xanh dương HUIT (`#0B519C` / `#0284C7` / `#196EC9`). Dùng cho AppBar, Nút bấm chính, Icon đang active, gạch chân Tab và viền bộ lọc.
- **Màu nền ứng dụng (Scaffold Background):** Xám xanh nhạt (`#F1F5F9` hoặc `#F4F6F8`). Tránh dùng nền trắng tinh toàn màn hình.
- **Màu nền Thẻ (Card Background):** Trắng tinh (`#FFFFFF`), kết hợp bóng đổ nhẹ (`blurRadius: 16 - 24, offset: Offset(0, 4), color: Colors.black.withOpacity(0.04)`).
- **Màu chữ (Typography):**
  - Tiêu đề / Nội dung chính: Xám đậm gần đen (`#1E293B` hoặc `#1A1A1A`), font-weight 700 - 800.
  - Phụ đề / Gợi ý (Subtitle / Placeholder): Xám nhạt (`#64748B` hoặc `#94A3B8`).
- **Màu trạng thái (Status Accent):**
  - **Đỏ:** Huy hiệu Badge thông báo, nút "Từ chối" (`#EF4444`, nền nhạt `#FEE2E2`).
  - **Xanh lá:** Trạng thái thành công, nút "Duyệt" (`#10B981`, nền nhạt `#D1FAE5`).
  - **Vàng cam:** Cảnh báo, icon đồng hồ chờ duyệt (`#F59E0B`, nền nhạt `#FEF3C7`).
- **Hệ thống Icon Pastel:** Các icon chức năng luôn được đặt trong vòng tròn hoặc ô vuông bo góc có màu nền pastel dịu nhẹ tương ứng với màu icon.

### 3.2. Bố cục & Độ bo góc (Border Radius)
- **Thẻ Card lớn:** Bo góc `16px - 22px`.
- **Ô nhập liệu (TextField), Nút bấm (Button):** Bo góc `10px - 12px`.
- **Bộ lọc / Badge / Tag (Pill-shape):** Bo tròn hoàn toàn `20px - 30px` (hình viên thuốc).
- **Icon Container:** Hình tròn (`BoxShape.circle`) hoặc vuông bo góc `12px`.

---

## 4. Chi tiết Thiết kế 17 Màn hình Mẫu & Ánh xạ vào Đồ án

### 4.1. Màn hình Đăng nhập (Auth / Login)
- **Bố cục:** Nền dải màu Gradient xanh lơ mượt mà (`#D6EEFB` -> `#EFF7FC`).
- **Phía trên:** Nút chọn ngôn ngữ (`🇻🇳 VI ∨`) bo tròn góc phải. Logo trường HUIT chính thức (`https://res.cloudinary.com/wpyhssfm/image/upload/logohuit`), Tên trường `TRƯỜNG ĐẠI HỌC CÔNG THƯƠNG TP.HCM` in đậm.
- **Khung Form (Card trắng bo tròn 22px):**
  - Ô nhập Mã số SV / Cán bộ: Icon thư/người màu xanh, nền xám nhạt không viền.
  - Ô nhập Mật khẩu: Icon khóa màu xanh, nút mắt ẩn/hiện mật khẩu.
  - Row ghi nhớ: Checkbox "Ghi nhớ mật khẩu" bên trái, liên kết "Quên mật khẩu?" màu xanh bên phải.
  - Hàng nút hành động: Nút `ĐĂNG NHẬP` màu xanh gradient trải dài, bên cạnh là nút vuông bo góc hỗ trợ Sinh trắc học (Vân tay / FaceID).
- **Chân trang:** Dòng bản quyền `© 2026 HUIT. All rights reserved.`

### 4.2. Khung App chính & Điều hướng đáy (MainLayout & Bottom Navigation Bar)
Toàn bộ hệ thống chạy trên thanh điều hướng 5 Tab cố định ở đáy:
1. **Trang chủ (`Home`):** Icon ngôi nhà.
2. **Lịch / Tiến độ (`Schedule`):** Icon lịch công tác / báo cáo tuần.
3. **Duyệt phiếu (`Approval`):** Icon văn bản kèm **Badge đỏ số lượng** (`3`) hiển thị số đề tài/báo cáo đang chờ duyệt.
4. **Bản tin (`News`):** Icon tờ báo tin tức.
5. **Thông tin (`Profile`):** Icon hồ sơ cá nhân.
- **Quy tắc Tab:** Tab Active đổi màu Xanh chủ đạo kèm vạch ngang nhỏ dưới chân. Tab Inactive màu xám.

### 4.3. Màn hình Trang chủ (Dashboard)
- **Header:** Nền Gradient xanh dương (`#0B66E4` -> `#2563EB`), Avatar tròn viền trắng, Tên người dùng (`Thương 15`), Chức vụ/Lớp, Chuông thông báo (kèm chấm đỏ).
- **Thao tác nhanh (Quick Action Grid):** Lưới 4 cột x 2 dòng các icon pastel có vuốt phân trang ngang 3 chấm:
  - *Ánh xạ sang Đồ án:* Đăng ký đề tài, Tạo nhóm, Nộp báo cáo tuần, Điểm số, Đề xuất đề tài, Duyệt đề tài.
- **Thẻ Tổng quan (Overview Card):** Khung card trắng, có thanh chọn ngày viên thuốc (`01/10/2026 >`), bên trong chia lưới các chỉ số tiến độ (Tổng giờ, Tiến độ %, Báo cáo đã nộp...).
- **Danh sách "Gợi ý cho bạn":** Card chứa các mục ListTile với icon tròn pastel bên trái, tiêu đề in đậm, phụ đề mô tả xám, chevron `>` bên phải.

### 4.4. Màn hình Thống kê & Danh sách (Stats & History)
- **AppBar:** Màu xanh, nút Back (`<`), Tiêu đề viết hoa (`TIẾN ĐỘ TUẦN`, `ĐỀ TÀI HƯỚNG DẪN`...).
- **Thanh TabBar phụ:** Ngay dưới AppBar: `Thống kê` | `Chờ duyệt` | `Lịch sử` (gạch chân xanh).
- **Thẻ chỉ số (Stats Circles):** 2 - 3 vòng tròn số liệu màu (Xanh, Cam, Xanh lá), số to in đậm, nhãn giải thích bên dưới.
- **Bộ lọc ngày tháng:** Dạng viên thuốc `[📅 26/09 – 25/10/2026 ∨]` viền xanh, nền xanh nhạt.
- **Empty State:** Icon tài liệu xám to ở giữa + chữ thông báo *"Không có dữ liệu trong khoảng thời gian này"*.
- **Nút FAB (Floating Action Button):** Nút tròn xanh dấu `+` góc dưới phải màn hình.

### 4.5. Nút FAB mở rộng (Speed Dial FAB)
- Khi bấm vào nút `+` góc dưới phải:
  - Nút chính đổi thành dấu `✕`.
  - Bung lên 2 nút tròn con kèm nhãn chữ: `Cho cá nhân` và `Cho nhóm/nhân viên`.
  - Dùng để chọn nhanh: "Đăng ký đề tài mới" hoặc "Nộp báo cáo tuần".

### 4.6. Màn hình Biểu mẫu Đề xuất / Nhập liệu (Form Input)
- **Header & Tab đối tượng:** TabBar 2 tab `Cho cá nhân` / `Cho nhóm`.
- **Card người nộp:** Avatar, Mã số SV, Họ tên, Đơn vị.
- **Các thành phần Form chuẩn:**
  - Dropdown chọn loại đề tài / đợt: Có icon loại dữ liệu bên trái, mũi tên xuống bên phải.
  - Chọn khoảng ngày: 2 ô song song `Ngày bắt đầu` - `Ngày kết thúc` kèm icon lịch.
  - Chuyển chế độ (Segmented Pill Toggle): Nút bấm dạng viên thuốc đôi (`Theo ngày` / `Theo giờ`, `Từng phần` / `Tổng thời gian`). Nút active có nền xanh chữ trắng.
  - Khung Textarea: Ô nhập lý do/nội dung thuyết minh đề tài nhiều dòng, bo góc 12px.
- **Thanh hành động đáy (Fixed Bottom Bar):**
  - Nút chính to dài màu xanh: icon máy bay giấy gửi đi `[ ✈ ĐỀ XUẤT ]` hoặc `[ ✈ ĐĂNG KÝ ]`.
  - Nút phụ tròn 3 chấm `[...]` bên cạnh để mở tùy chọn thêm.

### 4.7. Màn hình Phê duyệt (Approval List)
- **Tab trạng thái:** `Cần duyệt` | `Đã duyệt` | `Đã từ chối`.
- **Bộ lọc:** Dropdown `[::: Tất cả ∨]`, nút xanh lá viền `[✓ DUYỆT TẤT CẢ]`.
- **Thẻ phiếu duyệt (Approval Card):**
  - Header: Checkbox tròn chọn hàng loạt, Mã SV + Tên sinh viên, mũi tên `>`.
  - Body: Danh sách thông tin có icon minh họa (Tên đề tài, Giảng viên hướng dẫn, Thời gian nộp, Ghi chú).
  - Footer: 2 nút bấm ngang hàng:
    - Nút màu đỏ/hồng nhạt: `[✕ TỪ CHỐI]`
    - Nút màu xanh lá nhạt: `[✓ DUYỆT]`

### 4.8. Màn hình Bản tin / Tin tức (News Feed)
- **Thanh tìm kiếm:** Ô input bo tròn hoàn toàn `[🔍 Nhập tìm kiếm]`, bên cạnh là icon menu lưới.
- **Thẻ danh mục (Horizontal Chips):** `Tổ chức sự kiện`, `Thông báo khoa`, `Hướng dẫn đồ án`. Chip active có nền xanh đậm chữ trắng.

### 4.9. Màn hình Hồ sơ cá nhân (Profile)
- **Thẻ chính:** Tên sinh viên/giảng viên in hoa đậm, badge viên thuốc (`Sinh viên Khóa 11` / `Giảng viên hướng dẫn`), 2 ô icon Mã định danh và Số điện thoại.
- **Thẻ Accordion thông tin:** Khung có thể thu gọn/mở rộng `Thông tin đề tài`, `Thông tin học tập/công tác` (có nút bút chì để chỉnh sửa).
- **Nút hành động đáy:** `[ ✈ THAY ĐỔI THÔNG TIN ]`.

### 4.10. Màn hình Thông báo (Notifications)
- **AppBar:** Màu xanh, nút Back, tiêu đề `Thông báo (3)`, nút `Đọc tất cả`.
- **2 Tab phân loại:** `Chung (3)` | `Cá nhân`.
- **Thẻ thông báo:** Viền xanh nổi bật bên trái mép card, icon tròn vàng pastel, chấm đỏ báo chưa đọc, ngày giờ góc phải dưới.

---
*(Tài liệu này được cập nhật đầy đủ dựa trên phân tích toàn diện 17 màn hình thiết kế mẫu, làm chuẩn mực phát triển giao diện cho toàn bộ đội ngũ lập trình viên Mobile KLCN051).*
