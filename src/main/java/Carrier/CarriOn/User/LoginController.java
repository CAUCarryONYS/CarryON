package Carrier.CarriOn.User;

import Carrier.CarriOn.Chat.ChatService;
import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/auth")
@CrossOrigin(origins = "http://10.0.2.2:8085")
public class LoginController {

    private final UserRepository userRepository;
    private final HttpSession session;
    private final ChatService chatService;

    @Autowired
    public LoginController(UserRepository userRepository, HttpSession session, ChatService chatService) {
        this.userRepository = userRepository;
        this.session = session;
        this.chatService = chatService;
    }

    // 로그인
    @PostMapping("/login")
    public ResponseEntity<Map<String, Object>> loginUser(@RequestBody UserEntity user) {
        Optional<UserEntity> foundUser = userRepository.findByLoginId(user.getLoginId());

        Map<String, Object> response = new HashMap<>();
        if (!foundUser.isPresent()) {
            response.put("isLogin", "아이디를 잘못 입력하였습니다.");
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }

        UserEntity existingUser = foundUser.get();
        if (!existingUser.getPassword().equals(user.getPassword())) {
            response.put("isLogin", "비밀번호를 잘못 입력하였습니다.");
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }

        // 로그인 성공 - 세션에 사용자 ID 저장
        session.setAttribute("userId", existingUser.getId());

        // 사용자 정보 포함하여 반환
        Map<String, String> userInfo = new LinkedHashMap<>();
        userInfo.put("id", existingUser.getId().toString());
        userInfo.put("loginId", existingUser.getLoginId());
        userInfo.put("name", existingUser.getName());

        // 프로필 이미지 추가
        String profileImage = chatService.getProfileImageBase64(existingUser);
        userInfo.put("profileImage", profileImage);

        List<Map<String, String>> userInfoList = new ArrayList<>();
        userInfoList.add(userInfo);

        response.put("isLogin", "True");
        response.put("userInfo", userInfoList);
        return ResponseEntity.ok(response);
    }

    // 로그아웃
    @PostMapping("/logout")
    public ResponseEntity<Map<String, String>> logoutUser() {
        // 세션에서 userId 제거
        session.removeAttribute("userId");

        Map<String, String> response = new HashMap<>();
        response.put("isLogout", "True");

        return ResponseEntity.ok(response);
    }
}
