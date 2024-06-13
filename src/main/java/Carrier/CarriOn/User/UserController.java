package Carrier.CarriOn.User;

import Carrier.CarriOn.Chat.ChatService;
import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/user")
@CrossOrigin(origins = "http://10.0.2.2:8085")
public class UserController {

    private final UserService userService;
    private final HttpSession session;

    @Autowired
    public UserController(UserService userService, HttpSession session) {
        this.userService = userService;
        this.session = session;
    }

    // 회원정보 수정
    @PostMapping("/update")
    public ResponseEntity<Map<String, String>> updateUser(@RequestBody UserUpdateRequest updateRequest) {
        Long userId = (Long) session.getAttribute("userId");
        if (userId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(null);
        }

        userService.updateUser(userId, updateRequest);
        Map<String, String> response = new HashMap<>();
        response.put("message", "회원정보 수정 성공");
        return ResponseEntity.ok(response);
    }
}
