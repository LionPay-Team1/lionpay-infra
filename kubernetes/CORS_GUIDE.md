# LionPay 백엔드 CORS 설정 가이드

서브도메인 분리 아키텍처에서 프론트엔드가 API를 호출할 수 있도록 CORS를 설정합니다.

## 🔍 CORS가 필요한 이유

- **Frontend**: `https://lionpay.shop`
- **Admin**: `https://admin.lionpay.shop`
- **API**: `https://api.lionpay.shop`

세 개의 도메인이 모두 다르므로 브라우저의 CORS (Cross-Origin Resource Sharing) 정책에 의해 API 호출이 차단됩니다.
따라서 백엔드에서 명시적으로 CORS를 허용해야 합니다.

## 🔧 설정 방법

### 1. Auth 서비스 (Spring Boot)

파일: `lionpay-auth/src/main/java/com/likelion/lionpay_auth/config/SecurityConfig.java`

```java
package com.likelion.lionpay_auth.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;

@Configuration
public class SecurityConfig {

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        
        // ✅ 허용할 Origin 목록
        configuration.setAllowedOrigins(Arrays.asList(
            "https://lionpay.shop",      // 메인 앱
            "https://admin.lionpay.shop", // 어드민 앱
            "http://localhost:5173",      // 로컬 개발 (App)
            "http://localhost:5174"       // 로컬 개발 (Admin)
        ));
        
        // ✅ 허용할 HTTP 메서드
        configuration.setAllowedMethods(Arrays.asList(
            "GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"
        ));
        
        // ✅ 허용할 헤더
        configuration.setAllowedHeaders(Arrays.asList("*"));
        
        // ✅ 응답에 포함할 헤더
        configuration.setExposedHeaders(Arrays.asList(
            "Authorization",
            "Content-Type",
            "X-Requested-With"
        ));
        
        // ✅ 쿠키/인증정보 허용
        configuration.setAllowCredentials(true);
        
        // ✅ preflight 캐시 시간 (초 단위)
        configuration.setMaxAge(3600L);
        
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .cors()  // ✅ CORS 활성화
            .and()
            .csrf().disable()
            .authorizeRequests()
            .antMatchers("/api/v1/auth/health").permitAll()
            .anyRequest().authenticated();
        
        return http.build();
    }
}
```

### 2. Wallet 서비스 (.NET)

파일: `lionpay-wallet/Program.cs`

```csharp
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.DependencyInjection;

var builder = WebApplication.CreateBuilder(args);

// ✅ CORS 정책 설정
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowLionPayOrigins",
        corsBuilder =>
        {
            corsBuilder
                // ✅ 허용할 Origin 목록
                .WithOrigins(
                    "https://lionpay.shop",
                    "https://admin.lionpay.shop",
                    "http://localhost:5173",
                    "http://localhost:5174"
                )
                // ✅ 허용할 HTTP 메서드
                .AllowAnyMethod()
                // ✅ 허용할 헤더
                .AllowAnyHeader()
                // ✅ 응답에 포함할 헤더
                .WithExposedHeaders("Authorization", "Content-Type", "X-Requested-With")
                // ✅ 쿠키/인증정보 허용
                .AllowCredentials();
        });
});

// ... 다른 서비스 설정 ...

var app = builder.Build();

// ✅ CORS 미들웨어 활성화 (라우팅 전에 위치해야 함)
app.UseCors("AllowLionPayOrigins");

// ... 다른 미들웨어 설정 ...

app.MapGet("/api/v1/wallet/health", () => 
    Results.Ok(new { status = "healthy" }))
    .AllowAnonymous();

app.Run();
```

## ✅ 검증 방법

### 1. 로컬 환경 테스트

#### Preflight 요청 테스트
```bash
curl -X OPTIONS https://api.lionpay.shop/api/v1/auth/login \
  -H "Origin: https://lionpay.shop" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: content-type" \
  -v
```

응답 헤더에 다음이 포함되어야 합니다:
```
HTTP/1.1 200 OK
Access-Control-Allow-Origin: https://lionpay.shop
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, PATCH, OPTIONS
Access-Control-Allow-Headers: content-type
Access-Control-Allow-Credentials: true
Access-Control-Max-Age: 3600
```

#### 실제 요청 테스트
```bash
curl -X POST https://api.lionpay.shop/api/v1/auth/login \
  -H "Origin: https://lionpay.shop" \
  -H "Content-Type: application/json" \
  -H "Credentials: include" \
  -d '{"email":"test@example.com","password":"password"}' \
  -v
```

### 2. 브라우저 콘솔 테스트

개발자 도구(F12) → 콘솔에서 다음 JavaScript 실행:

```javascript
// Auth 서비스 테스트
fetch('https://api.lionpay.shop/api/v1/auth/health', {
  method: 'GET',
  credentials: 'include',
  headers: {
    'Content-Type': 'application/json'
  }
})
.then(response => response.json())
.then(data => console.log('Success:', data))
.catch(error => console.error('Error:', error));

// Wallet 서비스 테스트
fetch('https://api.lionpay.shop/api/v1/wallet/health', {
  method: 'GET',
  credentials: 'include',
  headers: {
    'Content-Type': 'application/json'
  }
})
.then(response => response.json())
.then(data => console.log('Success:', data))
.catch(error => console.error('Error:', error));
```

### 3. Kubernetes Pod 테스트

```bash
# Auth Pod 내부에서 Health Check
kubectl exec -it -n lionpay <AUTH_POD_NAME> -- \
  curl -X GET http://localhost:8080/api/v1/auth/health

# Wallet Pod 내부에서 Health Check
kubectl exec -it -n lionpay <WALLET_POD_NAME> -- \
  curl -X GET http://localhost:8081/api/v1/wallet/health
```

## 🚨 CORS 오류 해결

### 오류: "Access to XMLHttpRequest has been blocked by CORS policy"

#### 원인
- Origin이 허용 목록에 없음
- 백엔드에서 CORS 설정이 잘못됨
- 인증서 문제 (HTTPS/HTTP 혼합)

#### 해결 방법

1. **Origin 확인**
   ```bash
   # 브라우저 콘솔에서 현재 Origin 확인
   console.log(window.location.origin);  # https://lionpay.shop 또는 https://admin.lionpay.shop
   ```

2. **백엔드 설정 확인**
   - `setAllowedOrigins()`에 Origin이 정확히 포함되어 있는지 확인
   - 포트 번호도 포함해야 함 (예: `http://localhost:5173`)

3. **요청 메서드 확인**
   - `setAllowedMethods()`에서 `OPTIONS`, `POST` 등 필요한 메서드가 모두 포함되어 있는지 확인

4. **Credentials 확인**
   ```javascript
   // 쿠키를 포함하려면 반드시 credentials: 'include' 추가
   fetch('https://api.lionpay.shop/api/v1/auth/login', {
     credentials: 'include',  // ✅ 필수
     // ... 다른 옵션 ...
   });
   ```

### 오류: "Credential is not supported if the CORS header 'Access-Control-Allow-Origin' is '*'"

#### 원인
- `setAllowCredentials(true)`를 사용하면서 `setAllowedOrigins("*")`를 사용한 경우

#### 해결 방법
**반드시 구체적인 Origin 목록을 지정해야 합니다:**

```java
// ❌ 잘못된 방법
configuration.setAllowedOrigins("*");
configuration.setAllowCredentials(true);  // 에러!

// ✅ 올바른 방법
configuration.setAllowedOrigins(Arrays.asList(
    "https://lionpay.shop",
    "https://admin.lionpay.shop"
));
configuration.setAllowCredentials(true);  // OK
```

## 📝 정리

### Spring Boot (Auth)
- 파일: `SecurityConfig.java`
- 메인 설정: `corsConfigurationSource()` 메서드
- 활성화: `http.cors()`

### .NET (Wallet)
- 파일: `Program.cs`
- 메인 설정: `AddCors()` 및 `UseCors()` 메서드
- 활성화: `app.UseCors("정책명")`

### 반드시 포함할 설정
1. **AllowedOrigins**: 프론트엔드 도메인 목록
2. **AllowedMethods**: 필요한 HTTP 메서드 (GET, POST, PUT, DELETE, PATCH, OPTIONS)
3. **AllowedHeaders**: "*" (모든 헤더 허용)
4. **AllowCredentials**: true (쿠키/인증정보 허용)
5. **ExposedHeaders**: 클라이언트가 접근 가능한 응답 헤더

---

**참고**:
- 설계 문서 섹션: "2. CORS (Cross-Origin Resource Sharing) 설정"
- 각 서비스의 CORS 설정은 동일하게 유지해야 합니다.
