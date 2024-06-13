package Carrier.CarriOn.Friend;

import Carrier.CarriOn.User.UserService;
import jakarta.servlet.http.HttpSession;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/friends")
@CrossOrigin(origins = "http://10.0.2.2:8085")
public class FriendController {
    private final UserService userService;

    public FriendController(UserService userService) {
        this.userService = userService;
    }

    @PostMapping
    public ResponseEntity<String> addFriend(@RequestBody FriendRequest friendRequest, HttpSession session) {
        Long userId = (Long) session.getAttribute("userId");
        if (userId == null) {
            return ResponseEntity.badRequest().body("로그인이 필요합니다.");
        }

        userService.addFriend(userId, friendRequest.getFriendLoginId());
        return ResponseEntity.ok("친구 추가 및 채팅방 생성 성공");
    }

    @GetMapping
    public ResponseEntity<List<FriendDTO>> getFriendList(HttpSession session) {
        Long userId = (Long) session.getAttribute("userId");
        if (userId == null) {
            return ResponseEntity.badRequest().body(null);
        }

        List<FriendDTO> friendList = userService.getFriendListWithIds(userId);
        return ResponseEntity.ok(friendList);
    }

    @DeleteMapping("/{friendId}")
    public ResponseEntity<String> removeFriend(@PathVariable Long friendId, HttpSession session) {
        Long userId = (Long) session.getAttribute("userId");
        if (userId == null) {
            return ResponseEntity.badRequest().body("로그인이 필요합니다.");
        }

        userService.removeFriend(userId, friendId);
        return ResponseEntity.ok("친구 삭제 성공");
    }
}