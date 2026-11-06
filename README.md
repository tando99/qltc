# Sổ thu chi — bản Google cá nhân

Bản độc lập, giữ các chức năng thu chi, vay/cho vay, tiết kiệm, đầu tư.
Không phụ thuộc ChatGPT Sites. Không chứa dữ liệu, mã Google Sheet hoặc token của sổ cũ.

## Trạng thái

- Đã có mã đăng nhập Google (Authorization Code + PKCE + state + nonce).
- Gắn sổ theo mã Google account (sub), không theo thiết bị hoặc email hiển thị.
- Hai thiết bị đăng nhập cùng Google dùng cùng workbook trên máy chủ.
- Nếu mất liên kết máy chủ, tìm file có appProperties.financeOwner trong Drive trước khi tạo.
- Dùng OAuth client cố định. Đổi OAuth client/project có thể mất khả năng tìm file qua drive.file/appProperties; cần kế hoạch chuyển đổi.
- Có nút mở/tạo sổ, đăng xuất, ngắt kết nối Google và thông báo tạo file lần đầu.
- Bốn nhóm giao dịch đọc/ghi qua Sheets API; không lưu dữ liệu tài chính vào localStorage.
- Chặn tab cũ ghi nhầm sau khi đổi tài khoản. Phiên mỗi thiết bị độc lập.
- Kiểm tra đầu vào, chống gửi lặp, phát hiện phiên bản cũ, tuần tự hóa thao tác trong một tiến trình.
- Chưa kiểm thử Google OAuth/Sheets thật trên hosting: chưa có OAuth client và hosting được kết nối.
- Sổ và website cũ không thay đổi. Dữ liệu cũ CHƯA tự động chuyển sang sổ mới.

## Google Cloud

1. Tạo/chọn project tại https://console.cloud.google.com/.
2. Bật Google Drive API và Google Sheets API.
3. Google Auth Platform: tên app, email hỗ trợ, Audience External.
4. Quyền: openid, email, https://www.googleapis.com/auth/drive.file.
5. Tạo OAuth client kiểu Web application.
6. Authorized redirect URI: https://TEN-MIEN-APP/auth/google/callback.
   Local: http://localhost:3000/auth/google/callback.
7. Điền GOOGLE_CLIENT_ID và GOOGLE_CLIENT_SECRET trong Environment của hosting.
   Không gửi Client Secret trong chat, không commit vào Git.
8. Khi Testing, thêm tài khoản thử nghiệm. Chuyển Production và hoàn tất yêu cầu xác minh/branding Google áp dụng trước khi mời mọi người.
9. Trang quyền riêng tư: https://TEN-MIEN-APP/privacy.html.
   Bổ sung danh tính và địa chỉ liên hệ thực tế của quản trị viên trước khi công khai.

## Biến môi trường

- APP_ORIGIN: URL HTTPS chính thức, không có đường dẫn.
- GOOGLE_CLIENT_ID: OAuth web client ID.
- GOOGLE_CLIENT_SECRET: secret của client.
- TOKEN_KEY: 32 byte ngẫu nhiên mã hóa base64, tạo một lần:
  node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
- DATABASE_PATH: /data/app.sqlite khi chạy Docker/Render.
- TRUST_PROXY: 1 khi sau đúng một reverse proxy tin cậy; mặc định 0.

Giữ TOKEN_KEY ổn định và sao lưu riêng. Token máy chủ mã hóa AES-256-GCM,
ràng buộc mã Google account bằng AAD. DB giữ email, account ID, workbook ID,
phiên và token; không giữ bản sao số liệu tài chính.
Đây không phải mã hóa đầu cuối: máy chủ xử lý dữ liệu khi người dùng mở/sửa sổ.

## Chạy local

Cần Node.js 24.
1. npm ci
2. Sao chép .env.example thành .env, điền biến.
3. node --env-file=.env --import tsx server.ts
4. Mở http://localhost:3000.
5. Chưa cấu hình Google: trang báo chờ, không giả lập đăng nhập thành công.

npm run typecheck và npm test kiểm tra kiểu, phân tách tài khoản, đổi máy,
khôi phục workbook, chống tạo lại khi kết quả chưa chắc chắn, giao dịch và phép tính.

## Docker / Render

- Docker: docker compose up --build -d. DATABASE_PATH=/data/app.sqlite trong .env.
- Render: repository riêng chứa mã này; tạo Blueprint từ render.yaml hoặc Docker Web Service.
- render.yaml sử dụng gói trả phí và disk 1 GB. Xem/đồng ý chi phí trước khi tạo dịch vụ.
- Gắn persistent disk tại /data. Filesystem tạm không phù hợp cho DB liên kết tài khoản/phiên.
- Chỉ một instance, một Node process. Khóa hiện tại nằm trong bộ nhớ, không dùng để scale ngang.
- APP_ORIGIN phải khớp URL Render/miền riêng và redirect URI Google.
- /healthz báo tiến trình chạy, không xác nhận OAuth đã cấu hình.
- Backup SQLite và TOKEN_KEY; dùng SQLite backup API hoặc snapshot nhất quán, không copy riêng DB khi WAL đang ghi.
- Không log authorization code, cookie, token. Không publish .env hoặc thư mục data.

## Kiểm chứng trước khi mở cho mọi người

1. Tài khoản A đăng nhập, bấm Mở sổ; xác nhận file có đủ bốn trang.
2. Thêm/sửa/xóa mẫu ở bốn chức năng, kiểm tra trực tiếp Google Sheet và làm mới.
3. Thiết bị thứ hai đăng nhập A: phải cùng URL Sheet, cùng dữ liệu, không thêm file.
4. Tài khoản B: file riêng, không thấy dữ liệu A.
5. Đổi tài khoản ở một tab: tab cũ phải yêu cầu tải lại trước khi ghi.
6. Đăng xuất một thiết bị: thiết bị kia vẫn hoạt động.
7. Thu hồi quyền, đăng nhập lại, kiểm tra vẫn mở đúng file.
8. Thử từ chối quyền, mất mạng, dữ liệu sai, hai lần bấm lưu.
9. Tạo file gián đoạn: app tìm/khôi phục file có dấu nhận diện; không tự phát lại lệnh tạo.
   Nếu chưa thấy file sau khi đợi Drive đồng bộ, quản trị viên điều tra cờ creating;
   không đặt lại trước khi xác minh Google chưa tạo file.
10. Tránh sửa cùng một dòng trực tiếp trên Google Sheets trong lúc app lưu:
    Sheets không cung cấp compare-and-swap cho luồng này.

## Dữ liệu sổ cũ

Không tự chép dữ liệu riêng vào bản dùng chung.
Sau khi chủ sổ đăng nhập và xác nhận file mới, có thể chép giá trị các hàng dữ liệu
của bốn trang cũ vào bốn trang mới. Giữ nguyên tiêu đề, mã, kiểu dữ liệu, lịch sử trả nợ.
Chép giá trị ô; không thay thế/xóa trang vì app dùng mã trang cố định.
Kiểm tra số bản ghi và tổng tiền trước khi ngừng dùng bản cũ.
Không chép dữ liệu của chủ app vào sổ của người dùng khác.

## Nguồn kỹ thuật

https://developers.google.com/identity/protocols/oauth2/web-server
https://developers.google.com/identity/openid-connect/openid-connect
https://developers.google.com/workspace/drive/api/guides/api-specific-auth
https://github.com/googleapis/google-auth-library-nodejs
https://render.com/docs/disks
