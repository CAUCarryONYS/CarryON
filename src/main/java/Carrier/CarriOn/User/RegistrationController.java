package Carrier.CarriOn.User;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/registration")
//@CrossOrigin(origins = "http://localhost:8085")
@CrossOrigin(origins = "http://copytixe.iptime.org:8085")
public class RegistrationController {

    private final UserRepository userRepository;

    @Autowired
    public RegistrationController(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @PostMapping
    @CrossOrigin(origins = "http://localhost:8085")
    public ResponseEntity<Map<String, String>> registerUser(@RequestBody UserEntity newUser) {
        Map<String, String> response = new HashMap<>();

        // 아이디 중복 검사
        if (userRepository.findByLoginId(newUser.getLoginId()).isPresent()) {
            response.put("isSuccess", "중복된 loginId");
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
        }

        // 사용자 저장
        userRepository.save(newUser);
        response.put("isSuccess", "True");
        return ResponseEntity.ok(response);
    }
}
