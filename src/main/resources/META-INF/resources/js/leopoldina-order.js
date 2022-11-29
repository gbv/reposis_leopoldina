window.addEventListener('load', function() {
    let orderModal = document.getElementById('leopoldina-order-modal');

    let orderModalClose = document.getElementById('order-close');
    let orderModalSubmit = document.getElementById('order-submit');
    let orderModalCancel = document.getElementById('order-cancel');

    let orderSuccess = document.getElementById('order-success');
    let orderError = document.getElementById('order-error');


    let orderEmail = document.getElementById('order-email');
    let orderObjectID = document.getElementById('order-object-id');
    let orderName = document.getElementById('order-name');
    let orderAddress = document.getElementById('order-address');
    let orderComment = document.getElementById('order-comment');
    let orderAmount = document.getElementById('order-amount');
    let captchaInput = document.getElementById('captcha-input');
    let captchaImage = document.getElementById('captcha-image');
    let captchaRefresh = document.getElementById('captcha-refresh');
    let captchaPlay = document.getElementById('captcha-play');
    let captchaStop = document.getElementById('captcha-stop');

    orderModalSubmit.addEventListener('click', function() {

        let data = {
            email: orderEmail.value.trim(),
            objID: orderObjectID.value.trim(),
            name: orderName.value.trim(),
            address: orderAddress.value.trim(),
            comment: orderComment.value.trim(),
            action: 'order',
            captcha: captchaInput.value.trim(),
            amount: orderAmount.value.trim()
        }

        let invalid= false;
        if(data.email === '' || /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/.test(data.email) === false) {
            invalid = true;
            orderEmail.classList.add('is-invalid');
        } else {
            orderEmail.classList.remove('is-invalid');
        }

        if(data.name === '') {
            invalid = true;
            orderName.classList.add('is-invalid');
        } else {
            orderName.classList.remove('is-invalid');
        }

        if(data.address === '') {
            invalid = true;
            orderAddress.classList.add('is-invalid');
        } else {
            orderAddress.classList.remove('is-invalid');
        }

        if(data.amount === '') {
            invalid = true;
            orderAmount.classList.add('is-invalid');
        } else {
            orderAmount.classList.remove('is-invalid');
        }

        if(invalid) {
            return;
        }

        let xhr = new XMLHttpRequest();
        xhr.addEventListener('readystatechange', function() {
            if (xhr.readyState === 4) {
                if (xhr.status === 200) {
                    orderSuccess.classList.remove('d-none');
                    orderError.classList.add('d-none');
                    orderModalSubmit.classList.add('d-none');
                    orderModalCancel.classList.add('d-none');
                    orderModalClose.classList.remove('d-none');
                    orderModal.querySelectorAll('.form-row').forEach(function (row) {
                        row.classList.add('d-none');
                    });
                } else if(xhr.status === 422) {
                    orderError.classList.add('d-none');
                    captchaInput.classList.add('is-invalid');
                    captchaImage.src = captchaImage.src+'&rng='+Math.random();
                    audio = new Audio(window.webApplicationBaseURL + '/servlets/LeopoldinaOrderServlet?action=captcha-play&rng='+Math.random());
                    audio.addEventListener('ended', onEnd);

                    captchaInput.value = '';
                } else {
                    orderSuccess.classList.add('d-none');
                    orderError.classList.remove('d-none');
                }
            }
        });
        xhr.open('POST', window.webApplicationBaseURL + '/servlets/LeopoldinaOrderServlet?'+ new URLSearchParams(data).toString() , true);
        xhr.send();
    });

    captchaInput.addEventListener('input', function() {
        captchaInput.classList.remove('is-invalid');
    });

    captchaRefresh.addEventListener('click', function() {
        captchaImage.src = captchaImage.src+'&rng='+Math.random();
        audio = new Audio(window.webApplicationBaseURL + '/servlets/LeopoldinaOrderServlet?action=captcha-play&rng='+Math.random());
        audio.addEventListener('ended', onEnd);
    });

    var audio = new Audio(window.webApplicationBaseURL + '/servlets/LeopoldinaOrderServlet?action=captcha-play');

    audio.preload = 'auto';

    captchaPlay.addEventListener('click', function(e) {
        e.preventDefault()
        audio.play();
        captchaPlay.classList.add('d-none');
        captchaStop.classList.remove('d-none');
    });

    const onEnd = function(e) {
        e.preventDefault()
        audio.pause();
        audio.currentTime= 0;
        captchaPlay.classList.remove('d-none');
        captchaStop.classList.add('d-none');
    };

    captchaStop.addEventListener('click', onEnd);
    audio.addEventListener('ended', onEnd);

});